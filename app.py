from flask import Flask, redirect, url_for, render_template, request

app=Flask(__name__)

@app.route("/")
def home():
    app.route('/')
    return render_template("index.html")

def home2(name):
    # app.route('/home2/<name>')
    # return redirect(url_for('home'))
    return render_template("home.html")

def success(name):
    return "welcome %s" % name

def req():
    rt = {
        "username": "bob",
        "displayname": "bob",
        "default to display name?": "no",
        "email for account lockout / registration confirmation (optional)": "fuck no",
        "SSH public key": "123",
        "shell of choice": "/bin/bash",
        "have you read the rules?": "lolyeah"
        };
    return render_template("req.html", req_tab = rt)

def login():
    if request.method == "POST":
        user = request.form["nm"]
        return redirect(url_for('success', name = user))
    else:
        return redirect(url_for('home'))

if __name__=="__main__":
    app.add_url_rule('/home2/<name>', 'home2', home2)
    app.add_url_rule('/success/<name>', 'success', success)
    app.add_url_rule('/login', 'login', login, methods = ['POST', 'GET'])
    app.add_url_rule('/req', 'req', req, methods = ['POST', 'GET'])
    app.run(host="192.168.1.228",debug=True)
