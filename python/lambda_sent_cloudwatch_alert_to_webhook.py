import boto3
import json
import requests
from datetime import datetime

def lambda_handler(event, context):
    """
    处理 CloudWatch Alarm 状态变更事件
    支持发送到飞书群组
    """
    
    # 运维基础设施告警群
    webhook_url = "https://open.larksuite.com/open-apis/bot/v2/hook/1e90e260-9386-4520-9502-da0e620db419"
    
    try:
        # 记录事件基本信息
        print(f"处理CloudWatch告警事件 - 来源: {event.get('source', 'Unknown')}, 区域: {event.get('region', 'Unknown')}")
        
        # 解析 CloudWatch Alarm 事件
        alarm_data = parse_cloudwatch_alarm_event(event)

        # 记录解析结果
        print(f"告警解析完成 - 名称: {alarm_data['alarm_name']}, 状态: {alarm_data['previous_state']} → {alarm_data['state']}, 实例: {alarm_data['instance_id']}")
        
        # 构建飞书消息
        message = build_lark_message(alarm_data)
        
        # 发送到飞书
        response = send_to_lark(webhook_url, message)
        
        print(f"消息发送完成 - 状态码: {response.status_code}")
        
        return {
            'statusCode': response.status_code,
            'body': response.text
        }
        
    except Exception as e:
        error_msg = f"处理事件时发生错误: {str(e)}"
        print(error_msg)
        
        # 发送错误信息到飞书
        error_message = {
            "msg_type": "text",
            "content": {
                "text": f"🚨 Lambda处理CloudWatch告警时出错\n\n错误信息: {str(e)}\n\n请检查Lambda日志获取详细信息"
            }
        }
        try:
            send_to_lark(webhook_url, error_message)
        except:
            pass
        
        return {
            'statusCode': 500,
            'body': error_msg
        }

def parse_cloudwatch_alarm_event(event):
    """
    解析 CloudWatch Alarm 事件数据
    支持多种事件格式
    """
    # 尝试不同的事件格式
    alarm_data = {}
    
    # 格式1: EventBridge CloudWatch Alarm事件（带detail字段）
    if 'detail' in event:
        detail = event.get('detail', {})
        print("使用EventBridge格式解析")
        
        alarm_data = {
            'alarm_name': detail.get('alarmName', detail.get('alarm-name', 'Unknown')),
            'state': detail.get('state', {}).get('value', detail.get('newStateValue', 'Unknown')),
            'previous_state': detail.get('previousState', {}).get('value', detail.get('oldStateValue', 'Unknown')),
            'reason': detail.get('state', {}).get('reason', detail.get('newStateReason', detail.get('reason', 'No reason provided'))),
            'timestamp': detail.get('state', {}).get('timestamp', detail.get('stateChangeTime', '')),
            'region': event.get('region', 'Unknown'),
            'account': event.get('account', 'Unknown'),
            'resources': event.get('resources', []),
            'configuration': detail.get('configuration', {}),
            'instance_id': extract_instance_id(detail, event)
        }
    
    # 格式2: CloudWatch事件（带alarmData字段）
    elif 'alarmData' in event:
        alarm_data_obj = event.get('alarmData', {})
        print("使用alarmData格式解析")
        
        alarm_data = {
            'alarm_name': alarm_data_obj.get('alarmName', 'Unknown'),
            'state': alarm_data_obj.get('state', {}).get('value', 'Unknown'),
            'previous_state': alarm_data_obj.get('previousState', {}).get('value', 'Unknown'),
            'reason': alarm_data_obj.get('state', {}).get('reason', 'No reason provided'),
            'timestamp': alarm_data_obj.get('state', {}).get('timestamp', ''),
            'region': event.get('region', 'Unknown'),
            'account': event.get('accountId', event.get('account', 'Unknown')),
            'resources': [event.get('alarmArn', '')] if event.get('alarmArn') else [],
            'configuration': alarm_data_obj.get('configuration', {}),
            'instance_id': extract_instance_id_from_alarm_data(alarm_data_obj, event)
        }
    
    # 格式3: SNS消息格式
    elif 'Records' in event:
        print("使用SNS格式解析")
        for record in event.get('Records', []):
            if record.get('EventSource') == 'aws:sns':
                message = json.loads(record.get('Sns', {}).get('Message', '{}'))
                
                alarm_data = {
                    'alarm_name': message.get('AlarmName', 'Unknown'),
                    'state': message.get('NewStateValue', 'Unknown'),
                    'previous_state': message.get('OldStateValue', 'Unknown'),
                    'reason': message.get('NewStateReason', 'No reason provided'),
                    'timestamp': message.get('StateChangeTime', ''),
                    'region': message.get('Region', event.get('region', 'Unknown')),
                    'account': message.get('AWSAccountId', event.get('account', 'Unknown')),
                    'resources': [message.get('AlarmArn', '')],
                    'configuration': message,
                    'instance_id': extract_instance_id_from_sns(message)
                }
                break
    
    # 格式4: 直接的CloudWatch告警格式
    else:
        print("使用直接告警格式解析")
        alarm_data = {
            'alarm_name': event.get('AlarmName', event.get('alarmName', 'Unknown')),
            'state': event.get('NewStateValue', event.get('state', 'Unknown')),
            'previous_state': event.get('OldStateValue', event.get('previousState', 'Unknown')),
            'reason': event.get('NewStateReason', event.get('reason', 'No reason provided')),
            'timestamp': event.get('StateChangeTime', event.get('timestamp', '')),
            'region': event.get('Region', event.get('region', 'Unknown')),
            'account': event.get('AWSAccountId', event.get('account', 'Unknown')),
            'resources': event.get('resources', []),
            'configuration': event,
            'instance_id': extract_instance_id_from_direct(event)
        }
    
    return alarm_data

def extract_instance_id(detail, event=None):
    """
    从 CloudWatch Alarm 配置中提取实例ID
    """
    try:
        # 方法1: 从configuration.metrics中提取
        configuration = detail.get('configuration', {})
        metrics = configuration.get('metrics', [])
        
        for metric in metrics:
            metric_stat = metric.get('metricStat', {})
            metric_data = metric_stat.get('metric', {})
            dimensions = metric_data.get('dimensions', {})
            
            # 检查常见的实例ID字段
            instance_id = dimensions.get('InstanceId')
            if instance_id:
                return instance_id
            
            # 检查其他可能的字段名
            for key, value in dimensions.items():
                if 'instance' in key.lower() or 'id' in key.lower():
                    return value
        
        # 方法2: 从reason中提取
        reason = detail.get('state', {}).get('reason', detail.get('reason', ''))
        if 'InstanceId' in reason or 'instance' in reason.lower():
            import re
            # 匹配i-开头的实例ID
            match = re.search(r'(i-[a-f0-9]+)', reason)
            if match:
                return match.group(1)
        
        # 方法3: 从资源ARN中提取
        if event:
            for resource in event.get('resources', []):
                if 'instance' in resource:
                    match = re.search(r'instance/(i-[a-f0-9]+)', resource)
                    if match:
                        return match.group(1)
        
        # 方法4: 从告警名称中提取
        alarm_name = detail.get('alarmName', detail.get('alarm-name', ''))
        if alarm_name:
            match = re.search(r'(i-[a-f0-9]+)', alarm_name)
            if match:
                return match.group(1)
        
        return 'Unknown'
        
    except Exception as e:
        print(f"提取实例ID时出错: {str(e)}")
        return 'Unknown'

def extract_instance_id_from_sns(message):
    """
    从SNS消息中提取实例ID
    """
    try:
        # 从reason中提取
        reason = message.get('NewStateReason', '')
        if reason:
            import re
            match = re.search(r'(i-[a-f0-9]+)', reason)
            if match:
                return match.group(1)
        
        # 从告警名称中提取
        alarm_name = message.get('AlarmName', '')
        if alarm_name:
            match = re.search(r'(i-[a-f0-9]+)', alarm_name)
            if match:
                return match.group(1)
        
        return 'Unknown'
    except Exception as e:
        print(f"从SNS提取实例ID时出错: {str(e)}")
        return 'Unknown'

def extract_instance_id_from_direct(event):
    """
    从直接事件格式中提取实例ID
    """
    try:
        # 从reason中提取
        reason = event.get('NewStateReason', event.get('reason', ''))
        if reason:
            import re
            match = re.search(r'(i-[a-f0-9]+)', reason)
            if match:
                return match.group(1)
        
        return 'Unknown'
    except Exception as e:
        print(f"从直接格式提取实例ID时出错: {str(e)}")
        return 'Unknown'

def extract_instance_id_from_alarm_data(alarm_data_obj, event=None):
    """
    从alarmData结构中提取实例ID
    """
    try:
        # 方法1: 从configuration.metrics中提取
        configuration = alarm_data_obj.get('configuration', {})
        metrics = configuration.get('metrics', [])
        
        for metric in metrics:
            metric_stat = metric.get('metricStat', {})
            metric_data = metric_stat.get('metric', {})
            dimensions = metric_data.get('dimensions', {})
            
            # 检查InstanceId字段
            instance_id = dimensions.get('InstanceId')
            if instance_id:
                return instance_id
            
            # 检查其他可能的字段名
            for key, value in dimensions.items():
                if 'instance' in key.lower() or 'id' in key.lower():
                    return value
        
        # 方法2: 从reason中提取
        reason = alarm_data_obj.get('state', {}).get('reason', '')
        if reason and ('instance' in reason.lower() or 'i-' in reason):
            import re
            match = re.search(r'(i-[a-f0-9]+)', reason)
            if match:
                return match.group(1)
        
        # 方法3: 从告警名称中提取
        alarm_name = alarm_data_obj.get('alarmName', '')
        if alarm_name:
            import re
            match = re.search(r'(i-[a-f0-9]+)', alarm_name)
            if match:
                return match.group(1)
        
        # 方法4: 从配置描述中提取
        description = configuration.get('description', '')
        if description:
            import re
            match = re.search(r'(i-[a-f0-9]+)', description)
            if match:
                return match.group(1)
        
        return 'Unknown'
        
    except Exception as e:
        print(f"提取实例ID时出错: {str(e)}")
        return 'Unknown'

def build_lark_message(alarm_data):
    """
    构建飞书消息格式
    """
    # 状态图标映射
    state_icons = {
        'ALARM': '🔴',
        'OK': '🟢',
        'INSUFFICIENT_DATA': '🟡'
    }
    
    # 获取状态图标
    current_icon = state_icons.get(alarm_data['state'], '⚪')
    previous_icon = state_icons.get(alarm_data['previous_state'], '⚪')
    
    # 格式化时间
    try:
        if alarm_data['timestamp']:
            timestamp = datetime.fromisoformat(alarm_data['timestamp'].replace('Z', '+00:00'))
            formatted_time = timestamp.strftime('%Y-%m-%d %H:%M:%S UTC')
        else:
            formatted_time = '时间未知'
    except:
        formatted_time = alarm_data['timestamp'] if alarm_data['timestamp'] else '时间未知'
    
    # 检查是否有足够的信息
    is_missing_info = (
        alarm_data['alarm_name'] == 'Unknown' or 
        alarm_data['state'] == 'Unknown' or 
        alarm_data['reason'] == 'No reason provided'
    )
    
    # 构建消息内容
    if is_missing_info:
        message_text = f"""🚨 CloudWatch 告警状态变更 ⚠️ 数据不完整

{current_icon} 告警名称: {alarm_data['alarm_name']}
🔄 状态变更: {previous_icon} {alarm_data['previous_state']} → {current_icon} {alarm_data['state']}
🖥️ 实例ID: {alarm_data['instance_id']}
⏰ 时间: {formatted_time}
🌍 区域: {alarm_data['region']}
🏢 账户: {alarm_data['account']}

📋 详细信息:
{alarm_data['reason']}

🔗 资源: {', '.join(alarm_data['resources']) if alarm_data['resources'] else 'N/A'}

⚠️ 注意: 检测到部分信息缺失，可能是事件格式不匹配。请检查Lambda日志获取完整的原始事件数据。"""
    else:
        message_text = f"""🚨 CloudWatch 告警状态变更

{current_icon} 告警名称: {alarm_data['alarm_name']}
🔄 状态变更: {previous_icon} {alarm_data['previous_state']} → {current_icon} {alarm_data['state']}
🖥️ 实例ID: {alarm_data['instance_id']}
⏰ 时间: {formatted_time}
🌍 区域: {alarm_data['region']}
🏢 账户: {alarm_data['account']}

📋 详细信息:
{alarm_data['reason']}

🔗 资源: {', '.join(alarm_data['resources']) if alarm_data['resources'] else 'N/A'}"""

    # 如果有配置描述，添加到消息中
    if alarm_data['configuration'].get('description'):
        message_text += f"\n\n📝 描述: {alarm_data['configuration']['description']}"
    
    message = {
        "msg_type": "text",
        "content": {
            "text": message_text
        }
    }
    
    return message

def send_to_lark(webhook_url, message):
    """
    发送消息到飞书
    """
    response = requests.post(
        webhook_url,
        json=message,
        headers={'Content-Type': 'application/json'},
        timeout=10
    )
    
    if response.status_code != 200:
        print(f"发送到飞书失败: {response.status_code} - {response.text}")
    
    return response

# 测试函数（生产环境中注释掉）
# def test_handler():
#     """
#     测试函数，用于本地测试
#     """
#     test_event = {
#         "version": "0",
#         "id": "c4c1c1c9-6542-e61b-6ef0-8c4d36933a92",
#         "detail-type": "CloudWatch Alarm State Change",
#         "source": "aws.cloudwatch",
#         "account": "123456789012",
#         "time": "2019-10-02T17:04:40Z",
#         "region": "us-east-1",
#         "resources": [
#             "arn:aws:cloudwatch:us-east-1:123456789012:alarm:ServerCpuTooHigh"
#         ],
#         "detail": {
#             "alarmName": "ServerCpuTooHigh",
#             "configuration": {
#                 "description": "Goes into alarm when server CPU utilization is too high!",
#                 "metrics": [
#                     {
#                         "id": "30b6c6b2-a864-43a2-4877-c09a1afc3b87",
#                         "metricStat": {
#                             "metric": {
#                                 "dimensions": {
#                                     "InstanceId": "i-12345678901234567"
#                                 },
#                                 "name": "CPUUtilization",
#                                 "namespace": "AWS/EC2"
#                             },
#                             "period": 300,
#                             "stat": "Average"
#                         },
#                         "returnData": True
#                     }
#                 ]
#             },
#             "previousState": {
#                 "reason": "Threshold Crossed: 1 out of the last 1 datapoints [0.0666851903306472 (01/10/19 13:46:00)] was not greater than the threshold (50.0) (minimum 1 datapoint for ALARM -> OK transition).",
#                 "reasonData": "{\"version\":\"1.0\",\"queryDate\":\"2019-10-01T13:56:40.985+0000\",\"startDate\":\"2019-10-01T13:46:00.000+0000\",\"statistic\":\"Average\",\"period\":300,\"recentDatapoints\":[0.0666851903306472],\"threshold\":50.0}",
#                 "timestamp": "2019-10-01T13:56:40.987+0000",
#                 "value": "OK"
#             },
#             "state": {
#                 "reason": "Threshold Crossed: 1 out of the last 1 datapoints [99.50160229693434 (02/10/19 16:59:00)] was greater than the threshold (50.0) (minimum 1 datapoint for OK -> ALARM transition).",
#                 "reasonData": "{\"version\":\"1.0\",\"queryDate\":\"2019-10-02T17:04:40.985+0000\",\"startDate\":\"2019-10-02T16:59:00.000+0000\",\"statistic\":\"Average\",\"period\":300,\"recentDatapoints\":[99.50160229693434],\"threshold\":50.0}",
#                 "timestamp": "2019-10-02T17:04:40.989+0000",
#                 "value": "ALARM"
#             }
#         }
#     }
#     
#     result = lambda_handler(test_event, None)
#     print("测试结果:", json.dumps(result, indent=2, ensure_ascii=False))

# if __name__ == "__main__":
#     test_handler() 
