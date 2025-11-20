
## 打印所有分配 分配 备用域名 状态 blocklist 为表格
aws cloudfront list-distributions --query 'DistributionList.Items[*].[Id,join(`|`,Aliases.Items||[`no-custom-domain`]),Status,join(`,`,Restrictions.GeoRestriction.Items||[`no-restrictions`])]' --output table --region us-east-1
