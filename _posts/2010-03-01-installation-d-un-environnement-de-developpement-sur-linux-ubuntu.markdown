---
layout: post
title: Installation d'un environnement de développement Rails sur Linux Ubuntu
category: configuration
description: |
  Toutes les étapes et outils pour installer un environnement complet de développement Rails sur Linux Ubuntu : MacPorts, Git, MySQL, Ruby et Rails.
---

Avant de démarrer le développement proprement dit, il est nécessaire d'installer les logiciels nécessaires sur notre poste. Nous aurons évidemment besoin de Ruby et Rails. Pour la base de données, nous utiliserons MySQL. Nous installerons également Git pour versionner notre application. En ce qui concerne l'éditeur de texte ou IDE, chacun a sa préférence, nous donnerons simplement quelques pistes en fin d'article.

J'utilise Mac OS X, les instructions pour Ubuntu sont donc indicatives.

## Installation de Git

Nous commençons par mettre à jour la liste des paquets disponibles pour apt-get :

    {% highlight bash %}
    sudo apt-get update
    {% endhighlight %}

puis nous installons Git grâce à apt-get :

    {% highlight bash %}
    sudo apt-get install git-core
    {% endhighlight %}

## Installation de MySQL

Nous installons MySQL grâce à apt-get :

    {% highlight bash %}
    sudo apt-get install mysql-server-5.1 mysql-client-5.1 libmysql-ruby libmysqlclient-dev
    {% endhighlight %}

Vérifions que le serveur fonctionne :

    {% highlight bash %}
    mysql -u root -p
    show databases;
    {% endhighlight %}

Nous voyons la liste des bases de données par défaut (information_schema, mysql et test), MySQL fonctionne. Plusieurs outils de gestion des bases sont disponibles via le centre de téléchargement Ubuntu.

## Installation de Ruby et Rails

Nous installons Ruby et RubyGems grâce à apt-get :

    {% highlight bash %}
    sudo apt-get install ruby rubygems ruby-dev libopenssl-ruby
    {% endhighlight %}

Nous installons ensuite les gems nécessaires :

    {% highlight bash %}
    sudo gem install mysql rails --no-ri --no-rdoc
    {% endhighlight %}

Pour accéder facilement aux différents exécutables fournis par les gems, nous ajoutons la ligne suivante au fichier ~/.bashrc :

    {% highlight bash %}
    export PATH=/var/libs/gems/1.8/bin:$PATH
    {% endhighlight %}

Puis nous regénérons l'environnement :

    {% highlight bash %}
    source ~/.bashrc
    {% endhighlight %}

Nous pouvons alors tester l'ensemble des programmes installés :

    {% highlight bash %}
    ruby -v # ruby 1.8.7 (2009-06-12 patchlevel 174) [i486-linux]
    gem -v # 1.3.5
    rails -v # Rails 2.3.5
    {% endhighlight %}

Nous voilà fin prêts pour démarrer le développement d'une application !

## Autres outils

Voici une liste non exhaustive de logiciels facilitant le développement.

### Éditeurs de texte et IDE

- [Komodo Edit][komodo] :  une version libre de l'IDE d'ActiveState
- [Aptana][aptana] : une version d'Eclipse adapté au développement avec Ruby On Rails
- un grand nombre d'autres éditeurs sont disponibles par apt-get ou par le Centre de logiciels : emacs, vi, bluefish...

### GUI pour MySQL

- MySQL GUI Tools et plusieurs autres sont disponibles sur le Centre de logiciels

### GUI pour Git

Nous reviendrons dans un prochain article sur l'utilisation de Git. En attendant, voici quelques outils pour en faciliter l'utilisation.

- Git GUI : fourni avec Git
- d'autres GUI sont disponibles sur le Centre de logiciels

[komodo]: http://www.openkomodo.com/
[aptana]: http://www.aptana.com/