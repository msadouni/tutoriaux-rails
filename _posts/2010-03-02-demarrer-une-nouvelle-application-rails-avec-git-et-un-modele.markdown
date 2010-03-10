---
layout: post
title: Démarrer une nouvelle application Rails avec Git et un modèle
categories:
- configuration
- git
auteur: Matthieu Sadouni
chapo: |
  Rails permet de générer le squelette de base d'une application grâce à la simple commande `rails mon-appli`. Cette application est par contre vide, or en général nous utilisons toujours plusieurs fonctionnalités dans chacun de nos applications : enregistrement et connexion d'utilisateurs, pagination de résultats, tests unitaires, etc.
description: |
  Comment utiliser un modèle d'application pour la génération et le versionning avec Git pour faciliter la création d'un projet Rails.
---

Nous allons voir comment utiliser les modèles d'application pour générer un squelette incluant d'office les fonctionnalités couramment utilisées.

## Les modèles d'application

Les modèles d'application sont de simple fichiers Ruby contenant du code permettant d'effectuer un certain nombre d'actions à la création d'une application. Différentes méthodes sont disponibles, permettant d'inclure une gem ou un plugin, de manipuler git, de créer une route, de lancer un script, etc.

Pour indiquer à Rails d'utiliser un fichier modèle, il suffit d'utiliser le paramètre `- m` lors de la création d'une application :

    {% highlight bash %}
    rails mon-appli -m ~/rails-modele.rb
    {% endhighlight %}

Il est également possible d'indiquer un fichier situé sur un serveur web :

    {% highlight bash %}
    rails mon-appli -m http://gist.github.com/211697.txt
    {% endhighlight %}

Nous allons créer un fichier modèle qui réalise les actions suivantes :

- gestion de source avec Git
- installation de gems et de plugins
- configuration de la base de données

## Gestion de source avec Git

Comme nous allons versionner notre code avec Git, nous profitons du modèle d'application pour exécuter les commandes permettant d'initialiser un dépôt et de le paramétrer pour ignorer les fichiers qui ne seront pas versionnés : fichiers de configuration, de logs, temporaires...

    # ~/rails-modele.rb

    {% highlight ruby %}
    # Initialisation du dépôt
    git :init

    # Copie du fichier de configuration de la base de données vers une version d'exemple
    run "cp config/database.yml config/database.yml.default"

    # Ajout d'un fichier .gitignore dans chaque répertoire vide
    # Git ne versionne que le contenu des fichiers, un répertoire ou fichier vide est ignoré
    # Pour forcer la création des répertoires vides nous y insérons un fichier caché spécial
    run %{find . -type d -empty | xargs -I % touch %/.gitignore}

    # Ajout des fichiers à ignorer dans le fichier .gitignore principal
    file '.gitignore', <<-END
    log/*.log
    db/*.db
    db/*.sqlite3
    tmp/**/*
    config/database.yml
    END
    {% endhighlight %}

La méthode `git` permet de répliquer le fonctionnement de l'utilitaire en ligne de commande.

La méthode `run` permet d'exécuter directement une commande shell.

La méthode `file` permet de créer un fichier avec un contenu donné.

## Installation de gems et plugins

Une fois notre dépôt initialisé, nous allons pouvoir ajouter les gems et plugins couramment utilisés. Pour le moment nous nous en tiendrons au minimum : la pagination de résultats avec [WillPaginate](will_paginate). Le plugin d'inscription et de connexion des utilisateurs nécessitant plus d'explications, il fera l'objet d'un prochain article.

Nous ajoutons les lignes suivantes à notre fichier modèle :

    {% highlight ruby %}
    gem 'will_paginate', :source => 'http://gemcutter.org'
    rake 'gems:install', :sudo => true
    rake 'gems:unpack:dependencies'
    {% endhighlight %}

La méthode `gem` permet d'indiquer à Rails que l'application dépend d'une gem, en ajoutant au fichier `config/environment.rb` le nom et la version de la gem utilisée. Nous installons ensuite la gem grâce à rake avant d'en extraire le code dans le répertoire `vendor/gems` de l'application. Cela assure ainsi de versionner l'application avec l'ensemble de ses dépendances externes et d'éviter les mauvaises surprises lors du déploiement (gem non installée ou de version différente par exemple).

Nous allons également "freezer" Rails à la version utilisée dans l'application :

    {% highlight ruby %}
    rake 'rails:freeze:edge RELEASE=2.3.5'
    {% endhighlight %}

## Configuration de la base de données

Par défaut, Rails utilise en mode de développement la base de données SQLite. Or nous avons installé à l'[étape précédente](installation-environnement) MySQL pour retrouver en développement la même configuration que sur notre futur serveur de production. Il nous faut donc modifier le fichier de configuration de la base de données pour y indiquer nos paramètres :

    {% highlight ruby %}
    # Création du fichier de configuration de la base de données
    file 'config/database.yml', <<-END
    development:
      adapter: mysql
      database: database
      host: localhost
      username: username
      password: password
      encoding: utf8
    END
    database = ask("Nom de la base ?")
    username = ask("Nom d'utilisateur ?")
    password = ask("Mot de passe ?")
    run "sed -e 's/database:.*/database: #{database}/' -e 's/username:.*/username: #{username}/' -e 's/password:.*/password: #{password}/' config/database.yml > config/database.yml.tmp"
    run "mv config/database.yml.tmp config/database.yml"
    {% endhighlight %}

La méthode `ask` permet de demander des valeurs à l'utilisateur et de les utiliser ensuite. Il existe également les méthodes `yes?` et `no?` qui permettent d'effectuer ou non des actions suivant la réponse de l'utilisateur.

## Finalisation

L'application est maintenant prête à être créée, il ne nous reste plus qu'à enregistrer le code dans le dépôt et commiter :

    {% highlight ruby %}
    # Ajout dans le dépôt Git
    git :add => '.'
    git :commit => "-m 'Commit initial'"
    {% endhighlight %}

Nous pouvons maintenant créer notre application et le dépôt associé :

    {% highlight bash %}
    rails mon-appli -m ~/rails-modele.rb
    {% endhighlight %}

Le contenu du fichier rails-modele.rb est également disponible en ligne :

    {% highlight bash %}
    rails mon-appli -m http://gist.github.com/211697.txt
    {% endhighlight %}

Nous sommes maintenant prêts à démarrer le développement proprement dit.

[will_paginate]: http://github.com/mislav/will_paginate
[installation-environnement]: http://blog/installation-environnement