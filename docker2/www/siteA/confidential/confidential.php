
<html>
    <head>
        <title>Page protégée du site siteA</title>
    </head>
    <body>
        <h1> TOP SECRET </h1>
<?php
    $user = "admin";
    $password = "DB_ADMIN_PASSWORD";
    $database = "servicescomplexe-database";
    $table = "todo_list";
    try
    {   $db = new PDO(,$,$password);
        echo "<h2>TODO</h2> <ol>";
        foreach($db->query("SELECT content FROM $table") as $row)
         { echo "<li>" .$row['content'] . "</li>";
         }
        echo "</ol>";
    } 
    catch (PDOException $e)
    {   print "ERROR ! : " . $e->getMessage() . "<br/>";
        die();
    }
?>
    </body>
</html>
