# 知识库权限操作相关

## 接口详情

### 更新知识库权限

`/openapi/wiki/v1/update_knowledge_base_permission`


**触发场景**：用户需要修改知识库的权限设置,包括查看导出状态和加入类型等权限配置。可以选择性更新部分权限字段。

请求体结构：
```json
{
  "update_fields": "int32[], 必填, 更新字段列表, 至少指定一个, 取值: 0-未定义, 1-导出状态, 2-加入类型",
  "id": "string, 必填, 知识库ID",
  "name": "string, 可选, 知识库名称, 用于校验是否传错知识库, 长度限制1-25个字符（首尾不能为空格）",
  "visible_export_status": "int32, 可选, 查看及导出状态, 当update_fields包含1时必填, 取值: 0-未定义, 1-不可查看不可导出, 2-可查看不可导出, 3-可查看可导出",
  "join_type": "int32, 可选, 加入类型, 当update_fields包含2时必填, 取值: 0-未定义, 1-直接加入, 2-管理员批准加入, 3-付费加入"
}
```

返回结构：
```json
{}
空响应表示成功
```

### 加入知识库

`/openapi/wiki/v1/join_knowledge`


**触发场景**：用户加入指定的知识库, 当用户希望加入某知识库时, 可使用`/openapi/wiki/v1/search_knowledge_base_in_square`来搜索知识库的ID

请求体结构：
```json
{
  "knowledge_base_id": "string, 必填, 知识库 ID",
  "name": "string, 必填, 知识库名称"
}
```

返回结构：
```json
{}
```


### 更新知识访问状态

`/openapi/wiki/v1/update_knowledge_access_status`


**触发场景**：批量更新知识条目的访问权限状态。

请求体结构：
```json
{
  "knowledge_base_id": "string, 必填, 所属知识库 ID",
  "kb_name": "string, 选填, 所属知识库名称, 用于二次校验",
  "infos": [
    {
      "media_id": "string, 必填, 知识ID"
    },
    {
      "media_id": "string, 必填, 第二个需要操作的知识ID， infos数组的长度不超过10"
    }
  ],
  "access_status": "uint32, 必填, 访问状态：1-不可查看不可导出,2-可查看不可导出,3-可查看可导出"
}
```

返回结构：
```json
{}
```