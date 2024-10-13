const express = require("express");
const path = require("path");
const bodyParser = require("body-parser");
const { MongoClient, ServerApiVersion } = require("mongodb");
const cors = require("cors");
require("dotenv").config({ path: ".env.local" });
const app = express();

const uri = process.env.MONGO_URI;
const dbName = "leaderboard";

const client = new MongoClient(uri, {
  serverApi: {
    version: ServerApiVersion.v1,
    strict: true,
    deprecationErrors: true,
  },
});

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, "../public")));
app.use(bodyParser.urlencoded({ extended: true }));

app.get("/", (req, res) => {
  res.redirect("/leaderboard");
});

app.get("/leaderboard", (req, res) => {
  res.sendFile(path.join(__dirname, "../public/leaderboard.html"));
});

app.get("/placements", (req, res) => {
  // Dummy data for leaderboard (time is in seconds)
  const dummyData = [
    { name: "Warren", time: 0 },
    { name: "Jonathump", time: 256 },
    { name: "frog", time: 389 },
    { name: "tidbit", time: 477 },
    { name: "dumbo", time: 314 },
    { name: "superDuperPooper", time: 445 },
  ];
  const sortedData = dummyData.sort((a, b) => a.time - b.time);

  res.status(200).send({ placements: dummyData });
});

// This shoulddddd work -- add some more data and test it
// app.get("/placements", async (req, res) => {
//   try {
//     await client.connect();
//     const db = client.db(dbName);
//     const collection = db.collection("times");

//     // Fetch the placements sorted by time in ascending order
//     const placements = await collection.find().sort({ time: 1 }).toArray();

//     res.status(200).send({ placements: placements });
//   } catch (err) {
//     console.error(err);
//     res.status(500).send({ message: "Error fetching leaderboard data" });
//   }
// });

app.post("/receive_time", async (req, res) => {
  const { name, time } = req.body;
  console.log(`body of request: ${name}, ${time}`);
  if (!name || !time) {
    res.status(400).send({ message: "Name and time are required" });
  }
  try {
    await client.connect();
    const db = client.db(dbName);
    const collection = db.collection("times");
    const result = await collection.insertOne({
      name: name,
      time: time,
    });
    console.log(
      `Successfully inserted document with _id: ${result.insertedId}`
    );
  } catch (err) {
    console.error(err);
    res.status(500).send({ message: "Error saving data to database" });
  }
  res.status(200).send({ message: "Time received" });
});

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});

module.exports = app;
