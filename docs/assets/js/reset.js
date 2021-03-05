var database = firebase.database();
const bcrypt = dcodeIO.bcrypt;
sessionStorage.setItem('valid','false');
var loggedIn = {
    value: false
};

async function resetPassword(event) {
    event.preventDefault();
    let username = document.querySelector("#usernameInput").value;
    let oldPassword = document.querySelector("#oldPassword").value;
    let newpass1 = document.querySelector("#passwordInput").value;
    let newpass2 = document.querySelector("#passwordInput2").value;

    let myVal = await database.ref("users").orderByChild('username').equalTo(username).once("value");
    myVal = myVal.val();

    if (!myVal) {
        error("Incorrect Username.");
    } else {
        let userPassword;
        for (key in myVal) {
            userPassword = myVal[key].password;
        }
        if (bcrypt.compareSync(oldPassword, userPassword)) {
            if (newpass1 == newpass2) {
                var passw = /(?=.*\d)(?=.*[a-z])(?=.*[A-Z]).{6,}/;
                if(newpass1.match(passw)) { 
                    await firebase.database().ref("users").child(key).set({
                        username: username,
                        password: hash(newpass1),
                    });

                    sessionStorage.setItem('valid','true');
                    console.log(loggedIn);
                    window.location.href = "admin.html";
                }
                else { 
                    error("Password is not at least 6 characters with at least 1 numberic digit, 1 lowercase letter, and 1 uppercase letter");
                }
            } else {
                error("Passwords do not match");
            }
            
        } else {
            error("Incorrect Password");
        }
    }
}

async function LoginPage(event) {
    event.preventDefault();

    window.location.href = "login.html";
}

function error(error){
    document.querySelector("#error").innerHTML = error;
}


function hash(value) {
    let salt = bcrypt.genSaltSync(10);
    let hashVal = bcrypt.hashSync(value, salt);
    return hashVal;
}