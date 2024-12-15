<?php

$servername = "mysql_database";
$username = "php_user_password";
$password = "php_user_password";
$database = "test_database";

// Create connection
$conn = new mysqli($servername, $username, $password, $database);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

echo "Connected successfully";

// Close connection
$conn->close();

?>