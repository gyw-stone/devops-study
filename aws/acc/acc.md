## aws cli 创建加速器
aws globalaccelerator create-accelerator \
    --name testAccelerator \
    --tags Key="Name",Value="Example Name" Key="Project",Value="Example Project" \

## aws cli查看当前的加速器
aws globalaccelerator list-accelerators --region us-west-2
## aws cli 查看DNS name
aws cloudformation describe-stacks --stack-name Wireguard-dev-1 --query "Stacks[0].Outputs[?OutputKey=='AcceleratorDNS'].OutputValue" --output text
