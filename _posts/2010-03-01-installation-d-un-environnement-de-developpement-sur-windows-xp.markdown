---
layout: post
title: Installation d'un environnement de développement Rails sur Windows XP
category: configuration
description: |
  Toutes les étapes et outils pour installer un environnement complet de développement Rails sur Windows XP : MacPorts, Git, MySQL, Ruby et Rails.
---

Avant de démarrer le développement proprement dit, il est nécessaire d'installer les logiciels nécessaires sur notre poste. Nous aurons évidemment besoin de Ruby et Rails. Pour la base de données, nous utiliserons MySQL. Nous installerons également Git pour versionner notre application. En ce qui concerne l'éditeur de texte ou IDE, chacun a sa préférence, nous donnerons simplement quelques pistes en fin d'article.

J'utilise Mac OS X, les instructions pour Windows XP sont donc indicatives.

## Installation de Git

La meilleure option pour installer Git sur Windows semble être par l'intermédiaire de [msysGit](msysgit). Nous téléchargeons la dernière version stable et lançons l'installation.

À l'étape où apparaît un message en rouge et 3 choix nous choisissions la troisième option (l'option 1 est recommandée au cas où vous utilisez les utilitaires natifs de Windows find.exe et sort.exe, ceux-ci étant remplacés par leur version Unix avec l'option 3).

À l'étape du choix de format de fin de ligne, tout dépend de votre environnement :

- si vous travaillez avec des personnes sur Unix (Linux, Mac OS X), ou participez à des projets open source, choisissez l'option 1
- si vous travaillez seul sous Windows ou avec d'autres personnes toutes sur Windows, choisissez l'option 2

## Installation de MySQL

Nous téléchargeons [la version Community Server de MySQL][mysql] en choissisant Windows, Windows Essentials, Pick a mirror.

À la fin de l'installation nous choisissons "Configure MySQL now", "Standard configuration". Nous cochons ensuite la case "Include Bin Directory in Windows PATH" et saisissons le mot de passe root. Nous pouvons alors finir l'installation et vérifier que le serveur est bien installé en cliquant sur  "Démarrer > Exécuter > cmd" puis en tapant

    {% highlight bash %}
    mysql -u root -p
    show databases;
    {% endhighlight %}

Nous voyons la liste des bases de données par défaut (information_schema, mysql et test), MySQL fonctionne.

## Installation de Ruby et Rails

Nous téléchargeons le [programme d'installation de Ruby 1.8.6 pour Windows][ruby] et l'exécutons. Il faut ensuite cocher "Enable RubyGems" et "European Keyboard".

En ligne de commande nous vérifions que Ruby est accessible :

    {% highlight bash %}
    ruby -v # ruby 1.8.6 (2008-08-11 patchlevel 287) [i386-mswin32]
    {% endhighlight %}

Nous mettons RubyGems à jour, la version livrée avec Ruby est ancienne :

    {% highlight bash %}
    gem update
    gem -v # 1.3.5
    {% endhighlight %}

Nous pouvons maintenant installer Rails et les gems nécessaires :

    {% highlight bash %}
    gem install mysql rails --no-ri --no-rdoc
    {% endhighlight %}

Dernière petite chose, il semble y avoir parfois des soucis avec la connexion MySQL qui sont résolus en téléchargeant une [version plus ancienne de `libmySQL.dll`][libmysql] dans `c:\Ruby\bin`.

Nous voilà fin prêts pour démarrer le développement d'une application !

## Autres outils

Voici une liste non exhaustive de logiciels facilitant le développement.

### Éditeurs de texte et IDE

- [Komodo Edit][komodo] :  une version libre de l'IDE d'ActiveState
- [Aptana][aptana] : une version d'Eclipse adapté au développement avec Ruby On Rails
- [E-Editor][e-editor] : un clone de TextMate pour Windows, compatible avec les bundles de TextMate

### GUI pour MySQL

- [SQLyog][sqlyog]
- [MySQL GUI Tools][mysqlguitools]

### GUI pour Git

Nous reviendrons dans un prochain article sur l'utilisation de Git. En attendant, voici quelques outils pour en faciliter l'utilisation.

- Git GUI : fourni avec msysGit

[msysgit]: http://code.google.com/p/msysgit/
[mysql]: http://dev.mysql.com/downloads
[ruby]: http://rubyforge.org/frs/download.php/47082/ruby186-27_rc2.exe
[libmysql]: http://instantrails.rubyforge.org/svn/trunk/InstantRails-win/InstantRails/mysql/bin/libmySQL.dll
[komodo]: http://www.openkomodo.com/
[aptana]: http://www.aptana.com/
[e-editor]: http://www.e-texteditor.com/
[sqlyog]: http://code.google.com/p/sqlyog/
[mysqlguitools]: http://dev.mysql.com/downloads/gui-tools/5.0.html