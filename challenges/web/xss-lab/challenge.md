# 🔐 Web 安全挑战 — XSS 实验室

## challenge.yml
```yaml
name: "XSS 入门 — 反射型跨站脚本"
category: Web
difficulty: Easy
points: 100
hints:
  - cost: 10
    text: "尝试在搜索框中输入 HTML 标签"
  - cost: 20
    text: "`<script>alert(1)</script>` 是最经典的测试 payload"
flag: "CTF{xss_reflected_master_2024}"
```

## 题目描述 (CTFd 粘贴)

```
# XSS 入门 — 反射型跨站脚本

**难度**: ⭐ Easy | **分数**: 100

## 场景
你发现了一个搜索功能，它似乎会直接显示你输入的内容...

## 目标
利用反射型 XSS 漏洞获取管理员的 Cookie。

## 提示
- 反射型 XSS 指的是输入被服务器"反射"回页面
- 最常见的测试 payload 是什么？
- 试试用最基本的 `<script>` 标签

## 服务器信息
- 目标: http://xss-lab.challenges.local:8080
- 报告管理员bot: POST http://xss-lab.challenges.local:8080/report
```

## 挑战 Docker 构建

### Dockerfile
```dockerfile
FROM python:3.12-slim

RUN pip install flask gunicorn && \
    useradd -m -s /bin/bash challenger

WORKDIR /app
COPY app/ /app/

RUN chown -R challenger:challenger /app
USER challenger

EXPOSE 8080
CMD ["gunicorn", "-w", "2", "-b", "0.0.0.0:8080", "app:app"]
```

### app/app.py
```python
from flask import Flask, request, render_template_string

app = Flask(__name__)

# 管理员 Cookie（flag）
ADMIN_COOKIE = "flag=CTF{xss_reflected_master_2024}"

HTML_TEMPLATE = '''
<!DOCTYPE html>
<html>
<head><title>Search</title></head>
<body>
    <h2>搜索页面</h2>
    <form method="GET">
        <input name="q" placeholder="输入搜索关键词...">
        <button type="submit">搜索</button>
    </form>
    <div id="result">
        <h3>搜索结果: {{ query | safe }}</h3>
        <p>未找到相关内容</p>
    </div>
    <script>
        // 管理员访问时会携带此 cookie
        // 你的 payload 应该把它发送到你控制的服务器
    </script>
</body>
</html>
'''

@app.route('/')
def search():
    query = request.args.get('q', '')
    return render_template_string(HTML_TEMPLATE, query=query)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
```
