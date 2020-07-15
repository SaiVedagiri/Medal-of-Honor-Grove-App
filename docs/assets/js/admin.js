if (sessionStorage.getItem("valid") != "true") {
    window.location.href = "login.html"
} else{
    firebase.database().ref("locations").on("child_added", function (snapshot, prevChildKey) {
        var newPost = snapshot.val();
        let temp = [];
        temp.push(newPost.name);
        temp.push(newPost["qr-id"]);
        temp.push(newPost.latitude);
        temp.push(newPost.longitude);
        temp.push(newPost.text);
        temp.push(newPost.social);
        temp.push(snapshot.key);
        locations.push(temp);
        LocationsPopulate();
        scavengerPopulate();
    });
    
    firebase.database().ref("Scavenger").on("child_added", function (snapshot, prevChildKey) {
        var newPost = snapshot.val();
        let temp = [];
        temp.push(snapshot.key);
        temp.push(newPost);
        scavenger.push(temp);
        LocationsPopulate();
        scavengerPopulate();
    });
}

let locations = [];
let scavenger = [];
let editScavenger = true;
let editRow = false;
let missing = [];

function newLocationAdd() {
    if (editScavenger) {
        let name = document.getElementById("addName").value;
        let latitude = parseInt(document.getElementById("addLatitude").value);
        let longitude = parseInt(document.getElementById("addLongitude").value);
        let details = document.getElementById("addDetails").value;
        let social = document.getElementById("addSocial").value;
        let qr = Math.round(Math.random() * 10000000000);

        if (latitude != NaN && latitude > -90 && latitude < 90 && longitude != NaN && longitude > -180 && longitude < 180 && name != "") {
            firebase.database().ref("locations").push({
                latitude: latitude,
                longitude: longitude,
                name: name,
                "qr-id": qr,
                social: social,
                text: details
            });
        } else {
            alert("There is invalid or empty information. Please enter valid data to add location.");
        }
    }
}

function LocationsPopulate() {
    $("#locationTable tr").remove();

    var tablestring = "";
    tablestring += '<tr class="text-center"> <th style="width: 166px;">Location Name</th><th style="width: 131px;">QR Image</th><th style="width: 110.4px;">Latitude</th><th style="width: 116.8;">Longitude</th><th>Description</th><th style="width: 204px;">Social Text</th><th style="width: 108px;">Actions</th></tr>';

    for (var x = 0; x < locations.length; x++) {
        tablestring += `<tr id="row${x}" class="text-center"> <td>${locations[x][0]}</td><td><img src="https://api.qrserver.com/v1/create-qr-code/?data=${locations[x][1]}&amp;size=100x100" alt="" title="" /></td><td>${locations[x][2]}<br></td><td>${locations[x][3]}<br></td><td>${locations[x][4]}</td><td>${locations[x][5]}</td><td class="text-center"><button onclick="LocationEditPopulate(${x})" class="btn btn-primary" type="button" style="margin-bottom: 15px;">Edit</button><button onclick="LocationDeletePopulate(${x})" class="btn btn-primary" type="button">Delete</button></td></tr>`
    }

    tablestring += '<tr><td><input id="addName" type="text" style="width: 159px;"></td><td class="text-center">Auto</td><td><input id="addLatitude" type="text" style="width: 150px;"></td><td><input id="addLongitude" type="text" style="width: 150px;"></td><td class="text-center"><textarea id="addDetails" style="width:402px;"></textarea></td><td><input id="addSocial" type="text"></td><td class="text-center"><button id="addBtn" onclick="newLocationAdd()" class="btn btn-primary" type="button" style="margin-bottom: 15px;">Add</button></td></tr>'

    $("#locationTable tbody").append(
        tablestring
    );
}

function LocationEditPopulate(tableRow) {
    if (editScavenger) {
        editRow = true;
        let rowstring = `<tr><td><input id="editName${tableRow}" type="text" style="width: 159px;" value="${locations[tableRow][0]}"></td><td class="text-center" id="editQR${locations[tableRow][1]}">${locations[tableRow][1]}</td><td><input id="editLatitude${tableRow}" type="text" style="width: 150px;" value="${locations[tableRow][2]}"></td><td><input id="editLongitude${tableRow}" type="text" style="width: 150px;" value="${locations[tableRow][3]}"></td><td class="text-center"><textarea id="editDetails${tableRow}" style="width:402px;">${locations[tableRow][4]}</textarea></td><td><input id="editSocial${tableRow}" type="text" value="${locations[tableRow][5]}"></td><td class="text-center"><button onclick="SaveEdit(${tableRow})" class="btn btn-primary" type="button" style="margin-bottom: 15px;">Save</button><button onclick="DeleteEdit(${tableRow})" class="btn btn-primary" type="button">Discard</button></td>`
        document.getElementById(`row${tableRow}`).innerHTML = rowstring;
    }
}

function SaveEdit(row) {
    let name = document.getElementById(`editName${row}`).value;
    let latitude = parseInt(document.getElementById(`editLatitude${row}`).value);
    let longitude = parseInt(document.getElementById(`editLongitude${row}`).value);
    let details = document.getElementById(`editDetails${row}`).value;
    let social = document.getElementById(`editSocial${row}`).value;
    let qr = locations[row][1];
    let key = locations[row][6];

    if (latitude != NaN && latitude > -90 && latitude < 90 && longitude != NaN && longitude > -180 && longitude < 180 && name != "") {
        let temp = []
        temp.push(name, qr, latitude, longitude, details, social, key);
        locations[row] = temp;

        firebase.database().ref("locations").child(key).update(
            {
                name: name,
                latitude: latitude,
                longitude: longitude,
                text: details,
                social: social
            }
        );
        editRow = false;

        LocationsPopulate();
    } else {
        alert("There is invalid or empty information. Please enter valid data to save edits.");
    }
}

function DeleteEdit(row) {
    editRow = false;
    LocationsPopulate();
}

function LocationDeletePopulate(row) {
    if (editScavenger) {
        var retVal = confirm(`Do you want to delete ${locations[row][0]}?`);
        if (retVal == true) {
            firebase.database().ref("locations").child(locations[row][6]).remove();
            locations.splice(row, 1);
            LocationsPopulate();
        } else {
            LocationPopulate();
        }
    }
}

function scavengerPopulate() {
    $("#scavengerTable tr").remove();
    var tablestring = "";
    tablestring += '<tr class="text-center"><th style="width: 166px;">Location Name</th><th style="width: 204px;">Scavenger Hunt Location</th></tr>';

    for (var x = 0; x < scavenger.length; x++) {
        for (var y = 0; y < x; y++) {
            if (scavenger[y][0] > scavenger[x][0]) {
                temp = scavenger[y];
                scavenger[y] = scavenger[x];
                scavenger[x] = temp;
                break;
            }
        }
    }

    for (var x = 0; x < scavenger.length; x++) {
        for (var y = 0; y < locations.length; y++) {
            if (scavenger[x][1] == locations[y][6]) {
                tablestring += `<tr><td class="text-center">${locations[y][0]}</td><td class="text-center">${scavenger[x][0]}</td></tr>`
            }
        }
    }

    let missing = [];
    if (scavenger.length != locations.length) {

        for (x = 0; x < locations.length; x++) {
            let found = false;
            for (var y = 0; y < scavenger.length; y++) {
                if (scavenger[y][1] == locations[x][6]) {
                    found = true;
                }
            }
            if (found == false) {
                let temp = []
                temp.push(locations[x][6]);
                temp.push(x);
                missing.push(temp);
            }
        }
    }

    for (var x = 0; x < missing.length; x++) {
        tablestring += `<tr><td class="text-center">${locations[missing[x][1]][0]}</td><td class="text-center">N/A</td></tr>`
    }

    $("#scavengerTable tbody").append(
        tablestring
    );
}

function ScavengerEditPopulate() {
    $("#scavengerTable tr").remove();
    var tablestring = "";
    tablestring += '<tr class="text-center"><th style="width: 166px;">Location Name</th><th style="width: 204px;">Scavenger Hunt Location</th></tr>';

    for (var x = 0; x < scavenger.length; x++) {
        for (var y = 0; y < x; y++) {
            if (scavenger[y][0] > scavenger[x][0]) {
                temp = scavenger[y];
                scavenger[y] = scavenger[x];
                scavenger[x] = temp;
                break;
            }
        }
    }

    for (var x = 0; x < scavenger.length; x++) {
        for (var y = 0; y < locations.length; y++) {
            if (scavenger[x][1] == locations[y][6]) {
                tablestring += `<tr><td class="text-center">${locations[y][0]}</td><td class="text-center"><input id="scavenger${x}" value="${scavenger[x][0]}"></input></td></tr>`
            }
        }
    }

    missing = [];
    if (scavenger.length != locations.length) {

        for (x = 0; x < locations.length; x++) {
            let found = false;
            for (var y = 0; y < scavenger.length; y++) {
                if (scavenger[y][1] == locations[x][6]) {
                    found = true;
                }
            }
            if (found == false) {
                let temp = []
                temp.push(locations[x][6]);
                temp.push(x);
                missing.push(temp);
            }
        }
    }

    for (var x = 0; x < missing.length; x++) {
        let index = (parseInt(scavenger.length) + x);
        tablestring += `<tr><td class="text-center">${locations[missing[x][1]][0]}</td><td class="text-center"><input id="scavenger${index}" value="0"></input></td></tr>`
    }

    $("#scavengerTable tbody").append(
        tablestring
    );
}

async function editClick() {
    if (!editRow) {
        if (editScavenger) {
            document.getElementById("editbtn").innerHTML = '<button class="btn btn-primary text-center" type="button">Done</button>';
            editScavenger = false;
            ScavengerEditPopulate();
        } else {
            addArray = [];
            for (var x = 0; x < scavenger.length; x++) {
                let temp = [];
                temp.push(scavenger[x][1]);
                temp.push(document.getElementById(`scavenger${x}`).value);
                addArray.push(temp);
            }
            for (var x = 0; x < missing.length; x++) {
                let temp = [];
                temp.push(missing[x][0]);
                let index = (parseInt(scavenger.length) + x);
                temp.push(document.getElementById(`scavenger${index}`).value);
                addArray.push(temp);
            }

            indexArray = [];
            for (var x = 0; x < addArray.length; x++) {
                indexArray.push(addArray[x][1]);
            }

            duplicates = false;
            for (var x = 0; x < indexArray.length; x++) {
                for (var y = 0; y < indexArray.length; y++) {
                    if (indexArray[x] == indexArray[y] && indexArray[x] != 0 && x != y) {
                        duplicates = true;
                    }
                }
            }

            indexArray.sort();
            max = indexArray[indexArray.length - 1];
            minIndex = -1;
            for (var x = 0; x < indexArray.length; x++) {
                if (indexArray[x] == 1) {
                    minIndex = x;
                }
            }

            let order = false;
            if (minIndex != -1 && indexArray.length - minIndex == max) {
                order = true;
            }

            if (!duplicates) {
                if (order) {
                    scavenger = [];
                    missing = [];
                    await firebase.database().ref('Scavenger').remove();
                    for (var x = 0; x < indexArray.length; x++) {
                        if (addArray[x][1] != 0) {
                            let keyAdd = addArray[x][1];
                            let valueAdd = addArray[x][0];
                            await firebase.database().ref("Scavenger/" + keyAdd).set(valueAdd);
                        }
                    }
                    scavengerPopulate();
                    document.getElementById("editbtn").innerHTML = '<button class="btn btn-primary text-center" type="button">Edit</button>';
                    editScavenger = true;
                } else {
                    alert("You are missing indexes");
                }
            } else {
                alert("You have duplicate indexes.");
            }
        }
    }
}