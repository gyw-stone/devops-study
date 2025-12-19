import boto3
import json
import requests

def lambda_handler(event, context):
    #print(event)
    # 运维基础设施群
    webhook_url = ""
    # 提取 latestDescription
    latest_desc = event["Records"][0]["Sns"]
    latest_desc = json.loads(latest_desc["Message"])["detail"]["eventDescription"][0]["latestDescription"]
    # 处理双重转义
    clean_desc = bytes(latest_desc, "utf-8").decode("unicode_escape")
    # 解决编码问题
    clean_desc = clean_desc.encode("latin1").decode("utf8")
    # 处理换行符
    clean_desc = clean_desc.replace("\\n", "\n")
    # 打印测试
    # print("====== Decoded Message ======")
    # print(clean_desc)
    message = {
        "msg_type": "text",
        "content": {
        "text": clean_desc
        }
    }
    
    # 发送事件到 webhook
    response = requests.post(
        webhook_url,
        json=message,
        headers={'Content-Type': 'application/json'}
    )
    return {
        'statusCode': response.status_code,
        'body': response.text
    }
    # test and not notify
    # return {
    #     'statusCode': 200,
    #     'body': 'Message parsed successfully (not sent)'
    # }
