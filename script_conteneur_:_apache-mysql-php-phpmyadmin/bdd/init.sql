USE servicescomplexe-database;
CREATE TABLE IF NOT EXISTS todo_list
(
    id INT AUTO_INCREMENT PRIMARY KEY,
    content VARCHAR(255) NOT NULL,
    statut INT DEFAULT 0
);
INSERT INTO todo_list (content, statut) VALUES
('Sécuriser le site A.',0),
('Sécuriser le site B.',0),
('Créer une page secrète.',1),
('Faire fonctionner les services php, phpmyadmin, mysql et apache.',2);
