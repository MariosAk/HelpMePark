const express = require('express');
const bodyParser = require('body-parser');
const mysql = require('mysql');
const WebSocket = require('ws');
const http = require('http');
const uuidv4 = require('uuid').v4;
const https = require('https');
const { google } = require('googleapis');
const MESSAGING_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';
const SCOPES = [MESSAGING_SCOPE];

const app = express();
const port = 3000;
const server = http.createServer(app)

// Create a MySQL connection
const connection = mysql.createConnection({
  host: 'localhost',
  user: 'marios',
  password: '123456789',
  database: 'pasthelwparking'
});
const wss = new WebSocket.Server({server});
var previousLeavingID = -1;
var uniqueID = '';

wss.getUniqueID = function () {
    function s4() {
        return Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1);
    }
    return s4() + s4() + '-' + s4();
};

wss.on('connection', function (ws) {
    console.log('new connection');
    ws.id = wss.getUniqueID();
    uniqueID = ws.id;
    ws.send(JSON.stringify({ userIDForCache : ws.id }));
});

connection.connect((err) => {
  if (err) {
    console.error('Error connecting to database: ', err);
    res.status(505).send('Error connecting to database.: ', err);
    return;
  }
  console.log('Connected to database!');
});

function getAccessToken() {
  return new Promise(function(resolve, reject) {
    const key = require('./service-account.json');
    const jwtClient = new google.auth.JWT(
      key.client_email,
      null,
      key.private_key,
      SCOPES,
      null
    );
    jwtClient.authorize(function(err, tokens) {
      if (err) {
        reject(err);
        return;
      }
      resolve(tokens.access_token);
    });
  });
}

function getSearchersSendNotification(latitude, longitude, latestLeavingID, times_skipped = 0, time=""){
  let countNum = null;
  try{
  connection.query("SELECT COUNT(1) AS countNum WHERE EXISTS (SELECT * FROM searching)", (err, results) => {
    if(!err && results[0].countNum && results[0].countNum > 0){
      console.log(results[0].countNum);
      var query = "SELECT id, user_id, `time` FROM searching WHERE(ST_Distance_Sphere(point(center_longitude, center_latitude), point("+longitude+", " + latitude+"))) <= 500 ORDER BY `time` ASC";
      connection.query(query, (err, searcher) => {
        if(typeof searcher[times_skipped] !== 'undefined'){
        //getCarType(searcher[0].user_id);
        connection.query("SELECT carType, fcm_token FROM users WHERE user_id=?", searcher[times_skipped].user_id, (err, results) => {
          if(!err && results[0] != null){
            // wss.clients.forEach((client) => {
            //   if (searcher[times_skipped].user_id && client.id === searcher[times_skipped].user_id && client.readyState === WebSocket.OPEN) {
            //     client.send(JSON.stringify({latestLeavingID: latestLeavingID, _latitude: latitude, _longitude:longitude, carType:results[0].carType, times_skipped: times_skipped, time: searcher[times_skipped].time}));
            //   }
            // });
            getAccessToken().then(function(accessToken){
              console.log(accessToken);
            fetch("https://fcm.googleapis.com/v1/projects/pasthelwparking/messages:send", {
              method: "POST",
              body: JSON.stringify({
                message:
                {
                  token: results[0].fcm_token,
                  // notification: {
                  //   title: "A parking spot is free!",
                  //   body: "Someone just left an empty parking for you!"
                  // },
                  data: {
                    lat: latitude.toString(),
                    long: longitude.toString(),
                    user_id: searcher[0].user_id,
                    cartype: results[0].carType,
                    time: searcher[0].time.toString(),
                    id: searcher[0].id.toString(),
                    times_skipped: times_skipped.toString(),
                    latestLeavingID: latestLeavingID.toString()
                  },
                  android:{
                    notification:{
                      click_action: "FLUTTER_NOTIFICATION_CLICK"
                    }
                  }
                }
              }
              ),
              headers: {
                "Content-type": "application/json;",
                "Authorization": 'Bearer ' + accessToken
              }
            })
          });

          }
        });
      }
    }
    );
    }
    else if(!err && results[0].countNum && results[0].countNum == 0)
    {
      
    }
  });
}
catch{}
}

function sendFirebaseNotification()
{

}

// Use body-parser middleware to parse incoming requests
app.use(bodyParser.json());

app.post('/parking-skipped', (req, res) => {
  try{
    const times_skipped = req.body["times_skipped"];
    const time = req.body["time"];
    const latitude = req.body["latitude"];
    const longitude = req.body["longitude"];
    const latestLeavingID = req.body["latestLeavingID"];
    getSearchersSendNotification(latitude, longitude, latestLeavingID, times_skipped);
    res.send("Parking skipped");
  }
  catch{}
});

app.post('/set-claimedby', (req, res) => {
  try{
    const userid = req.body["user_id"];
    const latestLeavingID = req.body["latestLeavingID"];
    connection.query("UPDATE leaving SET claimedby_id=? WHERE id=?", [userid, latestLeavingID]);
    connection.query("DELETE FROM searching WHERE user_id=?", [userid]);
  }
  catch {}
});

// Define routes for GET and POST requests  TODO POST
app.get('/login-user', (req, res) => {
  try{
    const email = req.query.email;
    const password = req.query.password;
    connection.query('SELECT user_id, carType FROM users WHERE email=? AND password=?', [email, password], (err, results) => {
      if (err || !results[0].user_id) {
        console.error('Error at login: ', err);
        res.status(401).send('Error authenticating user.');
        return;
      }
      res.send(JSON.stringify({results, status:"Login successful", carType: results[0].carType}));
    });
  }
  catch{}
  });

app.post('/register-user', (req, res) => {
  try{
    // Extract the user data from the request body
    const { name, email, password } = req.body;
    const uuid = uuidv4();
    // Perform an INSERT query to add the user to the database
    connection.query('INSERT INTO users (name, email, password, user_id) VALUES (?,?,?,?)', [name, email, password, uuid], (err, result) => {
      if (err) {
        console.error('Error adding user: ', err);
        res.status(500).send('Error adding user');
        return;
      }
      res.send('User added successfully');
    });
  }
  catch{}
});

app.post('/add-searching', (req, res) => {
  try{
    //const user_id_body = JSON.parse(req.body["user_id"]);
    const user_id = req.body["user_id"];//user_id_body.results[0].user_id;
    const latitude = req.body["lat"];
    const longitude = req.body["long"];
    connection.query("INSERT INTO searching (center_latitude, center_longitude, user_id) VALUES(?, ?, ?)", [latitude, longitude, user_id], (err, result) => {
      if(err){
        console.error('Error inserting searcher: ', err);
        res.status(506).send('Error inserting searcher: ', err);
        return;
      }
      //res.send("Inserted search successfully");
    });
  }
  catch{}
});

app.post('/add-leaving', (req, res) => {
  try{
    //const user_id_body = JSON.parse(req.body["user_id"]);
    const user_id = req.body["user_id"];//user_id_body.results[0].user_id;
    const latitude = req.body["lat"];
    const longitude = req.body["long"];
    connection.query("INSERT INTO leaving (latitude, longitude, user_id) VALUES(?, ?, ?)", [latitude, longitude, user_id], (err, result) => {
      if(err){
        console.error('Error inserting leaving: ', err);
        res.status(506).send('Error inserting leaving: ', err);
        return;
      }
      //res.send("Inserted search successfully");
    });
  }
  catch{}
});

app.put('/update-userid', (req, res) => {
  try{
    const user_id = req.body["user_id"];
    const email = req.body["email"];
    connection.query("UPDATE users SET user_id=? WHERE email=?", [user_id, email], (err, result) => {

    });
  }
  catch{}
});

app.post('/update-center', (req, res) => {
  try{
  const user_id = req.body["user_id"];
  const latitude = req.body["lat"];
  const longitude = req.body["long"];
  connection.query("UPDATE searching SET center_latitude=?, center_longitude=? WHERE user_id = ?", [latitude, longitude, user_id], (err, result) => {
    if(err){
      console.error('Error updating center: ', err);
      res.status(506).send('Error updating center: ', err);
      return;
    }
    res.send("Center updated successfully");
  });
  }
  catch{}
});

app.delete('/cancel-search', (req, res) => {
  try{
    const user_id = req.body["user_id"];
    connection.query("DELETE FROM searching WHERE user_id=?", [user_id]);
  }
  catch{}
});

// Define a route for retrieving the latest record ID
app.get('/user-car-type', (req, res) => {
  try{
    // Perform a SELECT query to retrieve the latest record ID from the database
    connection.query('SELECT carType FROM users WHERE user_id='+req.params, (err, results) => {
      if (err) {
        console.error('Error retrieving carType: ', err);
        res.status(506).send('Error retrieving carType: ', err);
        return;
      }
      const latestRecordID = results[0].carType;
      res.send({ carType });
    });
  }
  catch{}
});

app.delete('/delete-leaving', (req, res) => {
  try{
    const leavingID = req.body["leavingID"];
    connection.query("DELETE FROM leaving WHERE ID=?", [leavingID]);
  }
  catch{}
});
  
  // Define a route for retrieving the latest coordinates
app.get('/latest-coordinates', (req, res) => {
  try{
    // Extract the latest record ID from the request query parameters
    const latestRecordID = req.query.latestRecordID;

    // Perform a SELECT query to retrieve the latest coordinates from the database
    connection.query(`SELECT latitude, longitude FROM leaving WHERE id=$latestRecordID`, (err, results) => {
      if (err) {
        console.error('Error retrieving latest coordinates: ', err);
        res.status(500).send('Error retrieving latest coordinates');
        return;
      }
      const latestCoordinates = results[0];
      res.send({ latestCoordinates });
    });
  }
  catch{}
});
  
// Define a route for tracking changes in real-time
app.get('/track-changes', (req, res) => {
  try{
    const query = "SELECT MAX(id) AS latest_id, user_id, longitude, latitude FROM leaving where claimedby_id IS NULL";
    // Set up a timer to periodically retrieve the latest record ID and coordinates
    const interval = setInterval(() => {
      // Perform a SELECT query to retrieve the latest record ID and coordinates
      connection.query(query, (err, results) => {
        if (err) {
          console.error('Error retrieving latest record ID : ', err);
          return;
        }
        const latestLeavingID = results[0].latest_id;
        const longitude = results[0].longitude;
        const latitude = results[0].latitude;
        if(previousLeavingID != -1){
            if(latestLeavingID != previousLeavingID){
              //find who to send notification to
              var searching = getSearchersSendNotification(latitude, longitude, latestLeavingID);
              console.log(searching);
              
              previousLeavingID = latestLeavingID;
            }
        }
        else
            previousLeavingID = latestLeavingID;
      });
    }, 1000);
  }
  catch{}
});

app.post('/register-fcmToken', (req, res) => {
  try{
    //CHANGE: only update if there the token isnt registered to anyone
    const user_id = req.body["user_id"];//user_id_body.results[0].user_id;
    const fcm_token = req.body["fcm_token"];
    connection.query("UPDATE users SET fcm_token=? where user_id=?", [fcm_token, user_id], (err, result) => {
      if(err){
        console.error('Error inserting fcm: ', err);
        res.status(506).send('Error inserting fcm: ', err);
        return;
      }
      //res.send("Inserted search successfully");
    });
  }
  catch{}
});

app.post('/get-userid', (req, res) => {
  try{
    const email = req.body["email"];
    connection.query('SELECT user_id FROM users WHERE email=?',[email], (err, results) => {
      if (err) {
        console.error('Error retrieving carType: ', err);
        res.status(506).send('Error retrieving carType: ', err);
        return;
      }
      const user_id = results[0].user_id;
      res.send({ user_id });
    });
  }
  catch{}
});

app.post('/get-latlon', (req, res) => {
  try{
    const userid = req.body["userid"];
    connection.query('SELECT center_latitude, center_longitude FROM searching WHERE user_id = ?',[userid], (err, results) => {
      if (err) {
        console.error('Error getting latitude/longitude: ', err);
        res.status(506).send('Error getting latitude/longitude: ', err);
        return;
      }
      res.send(JSON.stringify({results}));
    });
  }
  catch
  {

  }
});
  
app.post('/get-points', (req, res) => {
  try{
    const user_id = req.body["user_id"];
    connection.query('SELECT points FROM users WHERE user_id=?',[user_id], (err, results) => {
      if (err) {
        console.error(`Error retrieving points for user_id: ${user_id}`, err);
        res.status(506).send('Error retrieving points for user_id: ', err);
        return;
      }
      const points = results[0].points;
      res.send({ points });
    });
  }
  catch{}
});

app.post('/update-points', (req, res) => {
  try{
  const user_id = req.body["user_id"];
  const updatedPoints = req.body["points"];
  connection.query("UPDATE users SET points=? WHERE user_id = ?", [updatedPoints, user_id], (err, result) => {
    if(err){
      console.error(`Error updating points for user_id: ${user_id}`, err);
      res.status(506).send('Error updating points: ', err);
      return;
    }
    res.send("Points updated successfully");
  });
  }
  catch{}
});

app.post('/register-car', (req, res) => {
  try{
    const { carType, email } = req.body;
    connection.query('UPDATE users SET carType=? WHERE email = ?', [carType, email], (err, result) => {
      if (err) {
        console.error('Error registering car: ', err);
        res.status(500).send('Error registering car');
        return;
      }
      res.send('Car registered successfully');
    });
  }
  catch{}
});

app.post('/userid-exists', (req, res) => {
  try{
    const { user_id } = req.body;
    connection.query("SELECT * FROM leaving WHERE user_id=?", [user_id], (err, result) => {
      if (err) {
        console.error('Error finding user ', err);
        res.status(500).send('EError finding user');
        return;
      }
      res.send('User found successfully');
    });
  }
  catch{}
});

// Start the server
server.listen(port, () => {
  console.log(`Server listening on port ${port}`);
});