# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# This file creates a simple Airflow DAG that performs 4 tasks every 10 minutes:
# 1. Create an EMR cluster
# 2. Poll until the cluster is in WAITING state
# 3. Start a Notebook execution using the cluster created
# 4. Poll until the Notebook execution finishes

# Please configure correct values in method create_cluster and start_execution before use.

from airflow import DAG
from airflow.operators.python_operator import PythonOperator

from time import sleep
from datetime import datetime

import boto3, time
from builtins import range
from pprint import pprint

from airflow.utils.dates import days_ago
from airflow.operators.sensors import BaseSensorOperator
from airflow.contrib.sensors.emr_job_flow_sensor import EmrJobFlowSensor
from airflow.contrib.operators.emr_create_job_flow_operator import EmrCreateJobFlowOperator

from airflow.contrib.hooks.emr_hook import EmrHook
from airflow.contrib.sensors.emr_base_sensor import EmrBaseSensor
from airflow.utils import apply_defaults


class MyEmrJobFlowSensor(EmrJobFlowSensor):
    """
    Asks for the state of the JobFlow until it reaches WAITING/RUNNING state.
    If it fails the sensor errors, failing the task.
    :param job_flow_id: job_flow_id to check the state of
    :type job_flow_id: str
    """
    NON_TERMINAL_STATES = ['STARTING', 'BOOTSTRAPPING', 'TERMINATING']


class NotebookExecutionSensor(EmrBaseSensor):
    """
    Asks for the state of the NotebookExecution until it reaches a terminal state.
    If it fails the sensor errors, failing the task.
    :param execution_id: notebook execution_id to check the state of
    :type execution_id: str
    """

    NON_TERMINAL_STATES = ['START_PENDING', 'STARTING', 'RUNNING',
                           'FINISHING', 'STOP_PENDING', 'STOPPING']
    FAILED_STATE = ['FAILING', 'FAILED']
    template_fields = ['notebook_execution_id']
    template_ext = ()

    @apply_defaults
    def __init__(self, notebook_execution_id, *args, **kwargs):
        super(NotebookExecutionSensor, self).__init__(*args, **kwargs)
        self.notebook_execution_id = notebook_execution_id

    def get_emr_response(self):
        emr = EmrHook(aws_conn_id=self.aws_conn_id).get_conn()
        self.log.info('Poking notebook execution %s', self.notebook_execution_id)
        return emr.describe_notebook_execution(NotebookExecutionId=self.notebook_execution_id)

    @staticmethod
    def state_from_response(response):
        return response['NotebookExecution']['Status']

    @staticmethod
    def failure_message_from_response(response):
        state_change_reason = response['NotebookExecution']['LastStateChangeReason']
        if state_change_reason:
            return 'Execution failed with reason: ' + state_change_reason
        return None


def create_cluster():
    emr = boto3.client('emr', region_name=<FILL_IN_REGION, e.g. 'us-west-2'>)
    cluster = emr.run_job_flow(
        Name='Demo-Cluster',
        ReleaseLabel='emr-6.2.0',
        Applications=[{'Name': 'Spark'}, {'Name': 'Livy'}, {'Name': 'JupyterEnterpriseGateway'}],
        VisibleToAllUsers=True,
        Instances={
            'InstanceGroups': [
                {
                    'Name': "Master nodes",
                    'Market': 'ON_DEMAND',
                    'InstanceRole': 'MASTER',
                    'InstanceType': 'm5.xlarge',
                    'InstanceCount': 1,
                }
            ],
            'KeepJobFlowAliveWhenNoSteps': True,
            'TerminationProtected': False,
            'Ec2SubnetId': '<FILL_IN_SUBNET_ID, e.g subnet-123456>',
        },
        JobFlowRole='EMR_EC2_DefaultRole',
        ServiceRole='EMR_DefaultRole'
    )
    cluster_id = cluster['JobFlowId']
    print("Created an cluster: " + cluster_id)
    return cluster_id

def start_execution(**context):
    editor_id = <FILL_IN_NOTEBOOK_ID, e.g. 'e-ABCDEFG'>
    relative_path = <FILL_IN_NOTEBOOK_FILE_PATH, e.g. 'folder/demo.ipynb'>
    emr = boto3.client('emr', region_name=<FILL_IN_REGION, e.g. 'us-west-2'>)

    ti = context['task_instance']
    cluster_id = ti.xcom_pull(key='return_value', task_ids='create_cluster_task')
    print("Starting an execution using cluster: " + cluster_id)

    start_resp = emr.start_notebook_execution(
        EditorId=editor_id,
        RelativePath=relative_path,
        ExecutionEngine={'Id': cluster_id, 'Type': 'EMR'},
        ServiceRole='EMR_Notebooks_DefaultRole'
    )

    execution_id = start_resp['NotebookExecutionId']
    print("Started an execution: " + execution_id)
    return execution_id




with DAG('custom_cluster_execution_sensor_dag', description='Demo execution', schedule_interval='*/10 * * * *', start_date=datetime(2020,3,30), catchup=False) as dag:
    create_cluster_task = PythonOperator(
        task_id='create_cluster_task', 
        python_callable=create_cluster
    )


    cluster_sensor_task = MyEmrJobFlowSensor(
        task_id='check_cluster',
        job_flow_id="{{ task_instance.xcom_pull(task_ids='create_cluster_task', key='return_value') }}",
        aws_conn_id='aws_default',
    )

    start_execution_task = PythonOperator(
        task_id='start_execution_task', 
        python_callable=start_execution,
        provide_context=True
    )

    execution_sensor_task = NotebookExecutionSensor(
        task_id='check_notebook_execution',
        notebook_execution_id="{{ task_instance.xcom_pull(task_ids='start_execution_task', key='return_value') }}",
        aws_conn_id='aws_default',
    )

    create_cluster_task >> cluster_sensor_task >> start_execution_task >> execution_sensor_task


