<!DOCTYPE html>
<html>
    <head>
        <title>Page protégée du site siteB</title>
        <meta charset="utf-8"/>
    </head>
    <style>
body{
  background-color: #C6E7FF;
  font-family: Avantgarde, TeX Gyre Adventor, URW Gothic L, sans-serif;
}
table {
  width: 100%;
  border: 1px solid;
}
.todo{
  background-color: #B06161;
  text-align: center;

}
.inprogess{
  background-color: #FFCF9D;
  text-align: center;
}
.done{
  background-color: #D0E8C5;
  text-align: center;
}
      </style>
      <script>

      </script>
    <body>
        <h1> TOP SECRET </h1>
<?php
    $user = "admin";
    $password = "changeme";
    $database = "servicescomplexe-database";
    $table = "todo_list";


    $session = new mysqli("servicescomplexe-db-container",$user,$password, $database);

    if ($session->connect_error)
    {
      die("Connection failed: " . $session->connect_error);
    }
    
    $sql = "SELECT * FROM $table";
    $result = $session->query($sql);

    echo "<h2>Liste de tâches à faire</h2>";

    echo "<table>
    <tr> 
      <th>Tâche</th>
      <th>Statut</th>
    </tr>";

    if ($result->num_rows > 0) 
    {
       while( $row = $result->fetch_assoc() )
       { $statut = "";
         if( $row["statut"] == 0 )
         { $statut = "<td class=todo> A faire </td>";
         }
         if( $row["statut"] == 1 )
         { $statut = "<td class=inprogess> En cours </td>";
         }
         if( $row["statut"] == 2 )
         { $statut = "<td class=done> Fait </td>";
         }

         echo "<tr><td>" . $row["content"] . "</td>" . $statut . "</tr>";
       }
    } 
    else 
    {
      echo "0 results";
    }

    echo "</table>";
    $session->close();

?>
    </body>
</html>
