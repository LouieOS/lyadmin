import glob
import json
from flask import Flask, redirect, url_for, render_template, request

# lyadmin
# scripts and web form for a tilde / PAUS instance
#
# gashapwn
# Nov 2020
#
# https://git.lain.church/gashapwn/lyadmin
# gashapwn@protonmail.com
# or
# gasahwpn on irc.lainchan.org




app=Flask(__name__)

# Paths for conf file,
#           user list,
#           directory containing
#           account request files...
WORKING_DIR = "/home/gashapwn/lyadmin/";
ACCOUNT_DIR = "test/";
FULL_PATH = str(WORKING_DIR) + str(ACCOUNT_DIR)
CONF_PATH = str(WORKING_DIR) + "lyadmin.conf.json"

# Account requests are given ID numbers
# the first request will have the below
# id number
INIT_REQ_ID = "00000"

# Slurp the conf file
with open(CONF_PATH) as c: conf_json_str = c.read()
conf_obj = json.loads(conf_json_str)

# The main home page
@app.route("/")
def home():
    app.route('/')

    # Load the list of tilde users
    # to generate links for
    u_list = [];
    with open("user_list.txt") as u_file:
        for line in u_file.readlines():
            u_list.append(line.strip());
    
    return render_template("index.html", u_list=u_list, page_name="home")


# The page with rules
def rules():
    return render_template("rules.html")

# Generate HTML for a form widget
def widg_fun(widg):
    if(widg.w_type == "input"):
        # Return HTML for a single line input
        return "input id=id_%s name=%s type=text></input"%(widg.w_name, widg.w_name)
    elif(widg.w_type == "textarea"):
        # Return HTML for a big text input box
        return "textarea cols=40 id=id_%s name=%s rows=10 required=\"\""%(widg.w_name, widg.w_name)
    elif(widg.w_type == "check"):
        # Return HTML for a check box
        return "input id=id_%s name=%s type=checkbox required=\"\""%(widg.w_name, widg.w_name)
    return widg.w_type;

# Generate HTML for request form
# probably a strange way to do this...
def req():
    app.route('/req')
    class Widg:
        def __init__(self, w_name, w_type, w_opt):
            self.w_name = w_name
            self.w_type = w_type
            self.w_opt = w_opt

    # Configuration for our request form
    rt = {
        "username": Widg("username", "input", None),
        "email for account lockout / registration confirmation (optional)": Widg("email", "input", None),
        "SSH public key": Widg("pub_key", "textarea", None),
        "shell of choice": Widg("shell", "choice", map(lambda k : (k, conf_obj["shell"][k]), list(conf_obj["shell"].keys()))),
        "have you read the rules?": Widg("rule_read", "check", None)
        };
    return render_template("req.html", req_tab = rt, widg_fun = widg_fun, page_name="req")

# Process input from the /req page
def signup():
    app.route('/req/signup')

    # Get all the params from the POST
    # request
    username = request.form["username"]
    email = request.form["email"]
    shell = request.form["shell"]
    rule_read = request.form["rule_read"]

    is_email_user = False;

    # If a user didnt read the rules
    # send them back
    # Browser validations should
    # prevent this....
    if(rule_read != "on"):
        return redirect(url_for('req'))

    # Set placeholder if user didnt send an email
    if(len(email) > 1):
        is_email_user = True
    else:
        email = "NO_EMAIL"

    # All users requests have a sequential ID
    # this checks how many requests we have
    # and gives us a free ID so we can save
    # our request
    if(len(glob.glob("./test/[0-9]*ident*")) == 0):
        new_id = int(INIT_REQ_ID)
        new_id_str = INIT_REQ_ID
    else:
        max_id = max(list(map( lambda path : path.split("/")[-1].split(".")[0] , glob.glob("./test/[0-9]*ident*"))))
        zpad = len(max_id)
        new_id = int(max_id)+1
        new_id_str = str(new_id).zfill(zpad)

    # write the request to disk
    fn1 = str(FULL_PATH) + str(new_id_str) + ".ident"
    with open(fn1, "w") as ident_file:
        ident_file.write(str(username) + "\n")
        ident_file.write(str(email) + "\n")
        ident_file.write(str(shell) + "\n")
        ident_file.write(str(rule_read) + "\n")
        
    print(username + " " + email + " " + shell + " " + rule_read)
    return render_template("signup.html", is_email_user = is_email_user)
    

def login():
    if request.method == "POST":
        user = request.form["nm"]
        return redirect(url_for('success', name = user))
    else:
        return redirect(url_for('home'))

if __name__=="__main__":
    app.add_url_rule('/rules', 'rules', rules)
    app.add_url_rule('/login', 'login', login, methods = ['POST', 'GET'])
    app.add_url_rule('/req', 'req', req, methods = ['POST', 'GET'])
    app.add_url_rule('/req/signup', 'signup', signup, methods = ['POST'])
    app.run(host=conf_obj["listen_ip"],debug=True)
