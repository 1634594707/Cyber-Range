# 🗄️ SQL 注入挑战 — 登录绕过

## challenge.yml
```yaml
name: "SQLi — Union 注入与登录绕过"
category: Web
difficulty: Medium
points: 200
hints:
  - cost: 10
    text: "尝试在用户名输入框输入单引号 ' 观察错误信息"
  - cost: 20
    text: "SQL 注释符号 -- 可以截断后续的 SQL 语句"
  - cost: 30
    text: "试试 admin' -- 作为用户名，密码留空"
flag: "CTF{sqli_union_master_flag_2024}"
```

## 题目描述

```
# SQLi — Union 注入与登录绕过

**难度**: ⭐⭐ Medium | **分数**: 200

## 场景
一个内部管理系统的登录页面，安全团队似乎忘记做输入过滤...

## 目标
绕过登录验证，获取管理员权限，并从数据库中提取 flag。

## 步骤提示
1. 确认注入点：用户名输入 `'` 看是否有 SQL 错误
2. 绕过登录：构造注释截断 payload
3. 列数探测：`' ORDER BY 1--`
4. Union 查询：`' UNION SELECT 1,2,3--`
5. 获取数据：从 `flags` 表中提取 flag
```

## Dockerfile
```dockerfile
FROM php:8.2-apache

RUN docker-php-ext-install mysqli pdo_mysql && \
    a2enmod rewrite

COPY app/ /var/www/html/
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80
```

### app/login.php (核心代码)
```php
<?php
// 故意包含 SQL 注入漏洞的登录处理
$mysqli = new mysqli("mysql-db", "app", "weak_password", "challenge_db");

$username = $_POST['username'];  // ⚠️ 未过滤
$password = $_POST['password'];  // ⚠️ 未过滤

// 漏洞点：直接拼接用户输入
$query = "SELECT * FROM users WHERE username='$username' AND password='$password'";
$result = $mysqli->query($query);

if ($result && $result->num_rows > 0) {
    $user = $result->fetch_assoc();
    echo "Welcome, " . $user['username'] . "!<br>";
    
    // 如果以 admin 登录，显示 flag
    if ($user['is_admin']) {
        $flag_query = $mysqli->query("SELECT flag FROM flags LIMIT 1");
        $flag = $flag_query->fetch_assoc();
        echo "Flag: " . $flag['flag'];
    }
}
?>
```
