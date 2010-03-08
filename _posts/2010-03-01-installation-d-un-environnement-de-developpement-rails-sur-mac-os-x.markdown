---
layout: post
title: Installation d'un environnement de développement Rails sur Mac OS X
category: configuration
auteur: Matthieu Sadouni
chapo:
description: |
  Toutes les étapes et outils pour installer un environnement complet de développement Rails sur Mac OS X : MacPorts, Git, MySQL, Ruby et Rails.
---

Avant de démarrer le développement proprement dit, il est nécessaire d'installer les logiciels nécessaires sur notre poste. Nous aurons évidemment besoin de Ruby et Rails. Pour la base de données, nous utiliserons MySQL. Nous installerons également Git pour versionner notre application. En ce qui concerne l'éditeur de texte ou IDE, chacun a sa préférence, nous donnerons simplement quelques pistes en fin d'article.

Ruby et Ruby On Rails sont fournis sur les versions récentes (10.5 et 10.6) de Mac OS X. Nous allons cependant en installer nos propres versions, cela permettra de les mettre à jour plus facilement par la suite. Nous utilisons pour cela MacPorts.

## Installation de MacPorts et Git

MacPorts est un système de gestion de paquets pour Mac, dans le même genre qu'apt-get sous Debian. Il permet d'installer et de maintenir facilement un grand nombre de logiciels Unix adaptés pour Mac OS X.

Git est un système de [gestion de versions][scm-wikipedia] utilisé notamment pour le développement de Ruby on Rails.

### Installation de MacPorts

MacPorts nécessite l'installation de XCode, fourni sur le CD de Mac OS X (répertoire Optional Installs) ou disponible sur le site de l'ADC [Apple Developper Connection][adc]. Le téléchargement est gratuit, il suffit de créer un compte.

Une fois XCode installé, nous pouvons installer MacPorts. Il est disponible en téléchargement sur le [site de MacPorts][macports]. Il suffit de télécharger l'image DMG correspondant à la version de Mac OS X et de lancer le programme d'installation fourni. MacPorts est alors installé dans `/opt/local`.

Nous mettons à jour MacPorts pour être sûr de disposer des dernières versions des paquets :

    {% highlight bash %}
    sudo port -v selfupdate
    {% endhighlight %}

Nous ajoutons au fichier `.profile` situé dans notre répertoire utilisateur le chemin vers les exécutables et la documentation MacPorts

    # ~/.profile

    {% highlight bash %}
    export PATH=/opt/local/bin:$PATH
    export MANPATH=/opt/local/share/man:$MANPATH
    {% endhighlight %}

Puis nous rafraîchissons la session ouverte dans le terminal :

    {% highlight bash %}
    source ~/.profile
    {% endhighlight %}

### Installation de Git

Une fois MacPorts installé, nous installons git :

    {% highlight bash %}
    sudo port install git-core +bash_completion
    {% endhighlight %}

Après un certain temps (MacPorts compile l'ensemble des dépendances nécessaires à Git) MacPorts et Git sont installés. Nous pouvons passer à l'installation des outils nécessaires au développement proprement dit.

## Installation de MySQL

Nous installons MySQL :

    {% highlight bash %}
    sudo port install mysql5-server
    {% endhighlight %}

Une fois MySQL installé nous paramétrons les bases de données :

    {% highlight bash %}
    sudo mysql_install_db5
    {% endhighlight %}

Nous chargeons MySQL au démarrage de la session :

    {% highlight bash %}
    sudo launchctl load -w /Library/LaunchDaemons/org.macports.mysql5.plist
    {% endhighlight %}

Nous démarrons MySQL manuellement pour la première utilisation :

    {% highlight bash %}
    sudo mysqld_safe5 &
    {% endhighlight %}

Nous modifions le mot de passe root, en remplacant `new-password` par le mot de passe souhaité :

    {% highlight bash %}
    sudo mysqladmin5 -u root password 'new-password'
    {% endhighlight %}

Enfin nous vérifions le bon fonctionnement en ligne de commande :

    {% highlight bash %}
    mysql5 -u root -p
    show databases;
    {% endhighlight %}

Nous voyons la liste des bases de données par défaut (information_schema, mysql et test), MySQL fonctionne.

## Installation de Ruby et Rails

Nous installons Ruby :

    {% highlight bash %}
    sudo port install ruby
    {% endhighlight %}

Nous installons maintenant RubyGems, le système de gestion de modules Ruby :

    {% highlight bash %}
    sudo port install wget
    wget http://rubyforge.org/frs/download.php/60718/rubygems-1.3.5.tgz
    tar -xzf rubygems-1.3.5.tgz
    cd rubygems-1.3.5 && sudo ruby setup.rb
    sudo gem update --system
    {% endhighlight %}

Nous pouvons maintenant installer les gems nécessaires :

    {% highlight bash %}
    sudo gem install mysql rails --no-ri --no-rdoc
    {% endhighlight %}

Vérifions les chemins et versions de nos exécutables :

    {% highlight bash %}
    which ruby # /opt/local/bin/ruby
    which rails # /opt/local/bin/rails
    ruby -v # ruby 1.8.7 (2009-06-12 patchlevel 174) [i686-darwin10]
    rails -v # Rails 2.3.5
    {% endhighlight %}

Nous voilà fin prêts pour démarrer le développement d'une application !

## Autres outils

Voici une liste non exhaustive de logiciels facilitant le développement.

### Éditeurs de texte et IDE

- [Textmate][textmate] : l'éditeur que j'utilise, très puissant notamment grâce à son système de "snippets"
- [MacVim][macvim] : une version mac du célèbre éditeur vim, très puissant également mais demande un temps d'adaptation assez long
- [Komodo Edit][komodo] :  une version libre de l'IDE d'ActiveState
- [Aptana RadRails][aptana] : une version d'Eclipse adapté au développement avec Ruby On Rails

### GUI pour MySQL

- [Sequel Pro][sequelpro] : celui que j'utilise, très pratique pour les opérations courantes sur les bases de données (visualisation, modifications, import/export...)
- [MySQL GUI Tools][mysqlguitools]
- [Navicat][navicat]

### GUI pour Git

Nous reviendrons dans un prochain article sur l'utilisation de Git. En attendant, voici quelques outils pour en faciliter l'utilisation.

- [GitX][gitx] : celui que j'utilise, très pratique pour visualiser l'arborescence et l'historique d'un projet, gérer les commit etc
- [GitNub][gitnub]
- Git GUI : fourni avec Git, offre sensiblement les mêmes fonctionnalités mais sans l'interface "Mac-like". Se lance avec `git gui`.

### GUI pour MacPorts

- [Porticus][porticus] permet de visualiser, d'installer et de désinstaller des paquets

[scm-wikipedia]: http://fr.wikipedia.org/wiki/Gestion_de_versions
[adc]: http://developer.apple.com/mac/
[macports]: http://www.macports.org/
[textmate]: http://macromates.com/
[macvim]: http://code.google.com/p/macvim/
[komodo]: http://www.openkomodo.com/
[aptana]: http://www.aptana.com/
[sequelpro]: http://www.sequelpro.com/
[mysqlguitools]: http://dev.mysql.com/downloads/gui-tools/5.0.html
[navicat]: http://www.navicat.com/en/products/navicat_mysql/mysql_detail_mac.html
[gitx]: http://gitx.frim.nl/
[gitnub]: http://github.com/Caged/gitnub
[porticus]: http://porticus.alittledrop.com/