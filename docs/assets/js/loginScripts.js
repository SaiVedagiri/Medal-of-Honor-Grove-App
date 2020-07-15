var database = firebase.database();
const bcrypt = dcodeIO.bcrypt;
sessionStorage.setItem('valid','false');
var loggedIn = {
    value: false
};

async function signInEmail(event) {
    event.preventDefault();
    let username = document.querySelector("#usernameInput").value;
    let myVal = await database.ref("users").orderByChild('username').equalTo(username).once("value");
    myVal = myVal.val();
    if (!myVal) {
        error("Incorrect Username.");
    } else {
        let inputPassword = document.querySelector("#passwordInput").value;
        let userPassword;
        for (key in myVal) {
            userPassword = myVal[key].password;
        }
        if (bcrypt.compareSync(inputPassword, userPassword)) {
            sessionStorage.setItem('valid','true');
            console.log(loggedIn);
            window.location.href = "admin.html";
        } else {
            console.log(hash(inputPassword));
            error("Incorrect Password");
        }
    }
}

function error(error){
    document.querySelector("#error").innerHTML = error;
}


function hash(value) {
    let salt = bcrypt.genSaltSync(10);
    let hashVal = bcrypt.hashSync(value, salt);
    return hashVal;
}