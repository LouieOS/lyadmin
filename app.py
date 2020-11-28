import glob
import json

import re
import sshpubkeys

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
ACCOUNT_DIR = "req/";
FULL_PATH = str(WORKING_DIR) + str(ACCOUNT_DIR)
CONF_PATH = str(WORKING_DIR) + "lyadmin.conf.json"

# validation stuff
MAX_PUB_KEY_LEN = 5000
EMAIL_REGEX = "^[a-z0-9]+[\._]?[a-z0-9]+[@]\w+[.]\w{2,10}$"
KEY_REGEX = "^[ -~]+$"

# Account requests are given ID numbers
# the first request will have the below
# id number
INIT_REQ_ID = "00000"

# Slurp the conf file
with open(CONF_PATH) as c: conf_json_str = c.read()
conf_obj = json.loads(conf_json_str)

# A list of all the shell enums
conf_obj["shell_tup_list"] = list(map(
                lambda k : (
                    k, conf_obj["shell"][k]
                ),
                list(conf_obj["shell"].keys())
))

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

# Generates the page with rule. No logic needed.
def rules():
    return render_template("rules.html")

# Generate HTML for a form widget
def widg_fun(widg):
    if(widg.w_type == "input"):
        return "input id=id_%s name=%s type=text></input"%(
            widg.w_name, widg.w_name
        )
    elif(widg.w_type == "textarea"):
        return "textarea cols=40 id=id_%s name=%s rows=10 required=\"\""%(
            widg.w_name, widg.w_name
        )
    elif(widg.w_type == "check"):
        return "input id=id_%s name=%s type=checkbox required=\"\""%(
            widg.w_name, widg.w_name)
    return widg.w_type;

# Generate HTML for request form
# probably a strange way to do this...
def req():
    app.route('/req')
    class Widg:
        def __init__(self, w_name, w_type, w_opt):
            self.w_name = w_name
            self.w_type = w_type
            self.w_opt = w_opt # only for choice type widg

    # Configuration for our request form
    rt = {
        "username": Widg(
            "username",
            "input",
            None
        ),
        "email for account lockout / registration confirmation (optional)": Widg(
            "email",
            "input",
            None
        ),
        "SSH public key": Widg(
            "pub_key",
            "textarea",
            None
        ),
        "shell of choice": Widg(
            "shell",
            "choice",
            conf_obj["shell_tup_list"]
        ),
        "have you read the rules?": Widg(
            "rule_read", "check", None
        )
        };
    return render_template(
        "req.html",
        req_tab = rt,
        widg_fun = widg_fun,
        page_name="req"
    )

def handle_invalid_data(req):
    # print(str(e))
    return render_template("signup.html", is_email_user = False)

# Process input from user creation POST request
def signup():
    app.route('/req/signup')

    # Get all the params from the POST
    # request
    username = request.form["username"].strip()
    email = request.form["email"].strip()
    pub_key = request.form["pub_key"].strip()
    shell = request.form["shell"].strip()
    rule_read = request.form["rule_read"].strip()
    xff_header = request.headers["X-Forwarded-For"]

    is_email_user = False;

    # If a user didnt read the rules
    # send them back
    if(rule_read != "on"):
        return redirect(url_for('req'))

    # Set placeholder if user didnt send an email
    if(len(email) > 1):
        is_email_user = True
    else:
        email = "NO_EMAIL"

    # Validate shell
    if(not shell in conf_obj["shell"]):
        print("failed shell validation")
        return handle_invalid_data(req)

    # Validate email
    if( is_email_user and not re.search(EMAIL_REGEX, email)):
        print("failed email validation")
        return handle_invalid_data(req)
        
    # Validate the SSH pub key
    # Most software only handles up to 4096 bit keys
    if(len(pub_key) > MAX_PUB_KEY_LEN):
        print("key failed len check")
        return handle_invalid_data(req)

    # Only printable ascii characters in
    # a valid key
    # if(not re.search("^[ -~]+$", pub_key)):
    if(not re.search(KEY_REGEX, pub_key)):
        print("key failed regex")
        return handle_invalid_data(req)

    # Check the key against a library
    key = sshpubkeys.SSHKey(
        pub_key,
        strict_mode=False,
        skip_option_parsing=True
    )
    try:
        key.parse()
    except Exception as e:
        print("key failed lib validation")
        return handle_invalid_data(request)

    if(len(xff_header) < 1):
        xff_header = "NO_XFF"
    
    # All users requests have a sequential ID
    # The below picks the next ID based on
    # how many requests we already have saved
    # to disk
    if(len(glob.glob(ACCOUNT_DIR + str("[0-9]*ident*"))) == 0):
        new_id = int(INIT_REQ_ID)
        new_id_str = INIT_REQ_ID
    else:
        max_id = max(
            list(map(
                lambda path : path.split("/")[-1].split(".")[0],
                glob.glob(str(ACCOUNT_DIR) + "[0-9]*ident*")))
        )
        zpad = len(max_id)
        new_id = int(max_id)+1
        new_id_str = str(new_id).zfill(zpad)

    # write the request to disk
    fn1 = str(FULL_PATH) + str(new_id_str) + ".ident"
    with open(fn1, "w") as ident_file:
        ident_file.write(str(username) + "\n")
        ident_file.write(str(email) + "\n")
        ident_file.write(str(shell) + "\n")
        ident_file.write(str(pub_key) + "\n")
        ident_file.write(str(xff_header) + "\n")
        
    return render_template("signup.html", is_email_user = is_email_user)

@app.context_processor
def get_site_name():
      return {"site_name": conf_obj["site_name"]}
  
if __name__=="__main__":
    app.add_url_rule('/rules', 'rules', rules)
    app.add_url_rule('/req', 'req', req, methods = ['POST', 'GET'])
    app.add_url_rule('/req/signup', 'signup', signup, methods = ['POST'])
    app.run(host=conf_obj["listen_ip"],debug=True)
