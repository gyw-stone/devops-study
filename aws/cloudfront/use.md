
## 打印所有分配 分配 备用域名 状态 blocklist 为表格
aws cloudfront list-distributions --query 'DistributionList.Items[*].[Id,join(`|`,Aliases.Items||[`no-custom-domain`]),Status,join(`,`,Restrictions.GeoRestriction.Items||[`no-restrictions`])]' --output table --region us-east-1

## 访问/learn 自动重定向到/learn/ 
function handler(event) {
    var req = event.request;
    if (req.uri === "/learn") {
      return {
        statusCode: 302,
        statusDescription: "Moved Permanently",
        headers: { "location": { value: req.uri + "/" } }
      };
    }
    return req;
}
