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

# this is a weird way to do this
# right? 
def widg_fun(widg):
    if(widg.w_type == "input"):
        return "input id=id_%s name=%s type=text></input"%(widg.w_name, widg.w_name)
    elif(widg.w_type == "textarea"):
        return "textarea cols=40 id=id_%s name=%s rows=10 required=\"\""%(widg.w_name, widg.w_name)
    elif(widg.w_type == "check"):
        return "input id=id_%s name=%s type=checkbox required=\"\""%(widg.w_name, widg.w_name)
    return widg.w_type;

def req():
    class Widg:
        def __init__(self, w_name, w_type, w_opt):
            self.w_name = w_name
            self.w_type = w_type
            self.w_opt = w_opt
        
    rt = {
        "username": Widg("username", "input", None),
        "displayname": Widg("displayname", "input", None),
        "prefer display name?": Widg("default_disp", "check", None),
        "email for account lockout / registration confirmation (optional)": Widg("email", "input", None),
        "SSH public key": Widg("pub_key", "textarea", None),
        "shell of choice": Widg("shell", "choice", [("bash", "/bin/bash"), ("ksh", "/bin/ksh")]),
        "have you read the rules?": Widg("rule_read", "check", None)
        };

    # uhhh is this how you're supposed to do this?
    return render_template("req.html", req_tab = rt, widg_fun = widg_fun)

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
    app.run(host="104.248.118.130",debug=True)
