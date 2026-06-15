# 🔐 SSRF 挑战 — 内网探测

## challenge.yml
```yaml
name: "SSRF — 服务端请求伪造"
category: Web
difficulty: Medium
points: 250
hints:
  - cost: 15
    text: "网站有个「网页预览」功能，你输入 URL 它会去访问"
  - cost: 25
    text: "试试 file:///etc/passwd 协议"
  - cost: 30
    text: "内网有个管理面板在 http://172.21.0.2:8080/admin"
flag: "CTF{ssrf_pr0_1nt3rn4l_n3tw0rk}"
```

## 题目描述
```
# SSRF — 服务端请求伪造

**难度**: ⭐⭐ Medium | **分数**: 250

## 场景
一个网站提供了「网页预览」功能，可以输入 URL 让服务器去抓取内容。
但这可能不仅仅是抓取外部网页...

## 目标
利用 SSRF 漏洞探测内网服务，找到内网管理面板的 flag。

## 服务器信息
- 目标: http://ssrf.challenges.local:8080
- 提示: 试试不同协议 — http://, file://, gopher://
```

## 漏洞代码 (Python Flask)
```python
from flask import Flask, request
import requests

app = Flask(__name__)

INTERNAL_FLAG = "CTF{ssrf_pr0_1nt3rn4l_n3tw0rk}"

@app.route('/')
def index():
    return '''
    <h2>网页预览工具</h2>
    <form action="/preview" method="GET">
        <input name="url" placeholder="输入 URL..." style="width:400px">
        <button type="submit">预览</button>
    </form>
    <p>示例: https://example.com</p>
    '''

@app.route('/preview')
def preview():
    url = request.args.get('url', '')
    # ⚠️ 漏洞: 未限制 URL 目标，可访问内网
    try:
        resp = requests.get(url, timeout=5, verify=False)
        return f'<pre>{resp.text[:500]}</pre>'
    except Exception as e:
        return f'<pre>Error: {e}</pre>'

# ---- 内网服务（另一个容器） ----
# 实际部署时，这是一个独立容器，选手通过 SSRF 才能访问
@app.route('/admin')
def admin_panel():
    client_ip = request.headers.get('X-Forwarded-For', request.remote_addr)
    if client_ip.startswith('172.21.'):
        return f'<h3>Admin Panel</h3><p>Flag: {INTERNAL_FLAG}</p>'
    return 'Access Denied', 403

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
```
