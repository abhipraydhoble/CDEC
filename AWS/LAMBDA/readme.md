
# 🚀 Start and Stop EC2 Instances using Lambda

This setup allows you to start and stop EC2 instances automatically using AWS Lambda.

It helps in reducing cost by stopping instances when not in use and starting them when required.

---

## 📌 Step 1: Create EC2 Instance

- Launch a Linux EC2 instance  
- Note down the **Instance ID** (required in Lambda code)

---

## 📌 Step 2: Create IAM Role for Lambda

Create a role that allows Lambda to interact with EC2 and CloudWatch.

### Steps:

- Go to IAM → Create Role  
- Select **AWS Service**  
- Choose **Lambda** as use case  

### Attach Policies:

- `AWSLambdaBasicExecutionRole` → for CloudWatch logs  
- `AmazonEC2FullAccess` → to manage EC2 instances  

<img src="https://github.com/user-attachments/assets/8709cebf-53fe-418c-a3d4-86dbd5d7471f" />

---

## 📌 Step 3: Create Lambda Function

### Steps:

- Go to Lambda → Create Function  
- Provide function name  
- Select runtime → Python  
- Assign IAM role created earlier  

<img src="https://github.com/user-attachments/assets/2487a45c-bc34-46b8-b741-fde4e5279057" />

---

# ▶️ Start EC2 Instance (Lambda Code)

```python
import boto3

ec2 = boto3.client('ec2')

def lambda_handler(event, context):
    instance_id = 'i-0a30a69aab79a1275'
    
    try:
        ec2.start_instances(InstanceIds=[instance_id])
        print(f'Starting instance {instance_id}')
        return f'Instance {instance_id} is starting'
    
    except Exception as e:
        print(f'Error: {str(e)}')
        return f'Error: {str(e)}'
````

### Test Event

```json
{
    "action": "start"
}
```

<img src="https://github.com/user-attachments/assets/3c8b6f18-c9a6-466d-8d67-e167583a33c6" />
<img src="https://github.com/user-attachments/assets/b76c4684-f8f5-4c33-bf34-0cf073ec1807" />

---

# ⏹️ Stop EC2 Instance (Lambda Code)

```python
import boto3

ec2 = boto3.client('ec2')

def lambda_handler(event, context):
    instance_id = 'i-0a30a69aab79a1275'
    
    try:
        ec2.stop_instances(InstanceIds=[instance_id])
        print(f'Stopping instance {instance_id}')
        return f'Instance {instance_id} is stopping'
    
    except Exception as e:
        print(f'Error: {str(e)}')
        return f'Error: {str(e)}'
```

### Test Event

```json
{
    "action": "stop"
}
```

<img src="https://github.com/user-attachments/assets/7f126e21-c83b-452d-a810-3a6470ce5102" />
<img src="https://github.com/user-attachments/assets/596e1207-fe0b-4dfb-8538-719c565a329c" />

---

## 🧠 Key Understanding

* Lambda can automate EC2 operations
* Useful for cost optimization
* No need to manually start/stop instances
* Can be scheduled using CloudWatch Events (EventBridge)

---

## 🚀 Real-World Use Case

* Stop EC2 instances after office hours
* Start instances before working hours
* Automate non-production environments



```
