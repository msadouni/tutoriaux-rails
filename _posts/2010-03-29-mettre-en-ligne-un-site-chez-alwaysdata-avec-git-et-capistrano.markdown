---
layout: post
title: Mettre en ligne un site chez Alwaysdata avec Git et Capistrano
categories: configuration, git
auteur: Matthieu Sadouni
chapo: La mise en ligne d'un site par chargement FTP est fastidieuse et source d'erreur. Voyons comment automatiser ce processus avec Capistrano, un outil de déploiement automatisé.
description: |
  Comment mettre en ligne un site Rails versionné avec Git de manière automatisée avec Capistrano chez Alwaysdata.
---

[Capistrano][capistrano] est un outil permettant entre autres de mettre en ligne un site de manière automatique et fiable. Il offe plusieurs avantages intéressants comme la mise à jour de la base de données à partir des migrations et la possibilité de revenir facilement à une version antérieure en cas de problème.

[Alwaysdata][alwaysdata] est aujourd'hui, à ma connaissance, le seul hébergeur français à proposer un hébergement mutualisé pour Ruby on Rails. Les performances sont bonnes, les outils nombreux (dont un accès SSH complet avec support de git, un accès SFTP et MySQL accessible de l'extérieur) et le support excellent. Une sauvegarde quotidienne sur 30 jours des fichiers et bases de données est également réalisée de manière automatique.

## Prérequis

Par souci de simplicité, nous partons du principe que le code est versionné avec Git, que toutes les gems utilisées sont dépaquetées dans `vendor` avec `rake gems:unpack:dependencies`, et que Rails est également dépaqueté avec `rake rails:freeze:edge RELEASE=x.x.x`. Cela évite notamment de devoir installer toutes les gems sur le serveur et permet de s'assurer qu'une mise à jour sur le serveur ne cassera pas notre application. De plus cela permet d'utiliser une version de Rails différente de celles installées sur Alwaysdata. Pour plus d'informations, se reporter à [l'article sur le démarrage d'une application Rails avec Git][article-demarrage-appli].

## Hébergement du dépôt Git

Pour commencer, il nous faut héberger notre dépôt à un emplacement accessible depuis le serveur pour que Capistrano puisse y récupérer la dernière version du code. Par souci de simplicité, nous allons l'héberger sur notre compte Alwaysdata puisque Git y est disponible.

Après avoir ouvert un compte, nous activons l'utilisateur SSH dans la partie "Accès Distant > SSH" de la console d'administration.

Pour ne pas avoir à saisir le mot de passe à chaque déploiement, nous allons générer une clé publique sur notre poste et la copier sur le serveur.

Des instructions pour Windows, Mac OS X et Linux sont disponibles sur le [wiki d'Alwaysdata][wiki-cle-publique]. Je reprends ici les indications pour Mac OS X. 

    # Génération de la clé
    {% highlight bash %}
    $ mkdir -p ~/.ssh
    $ chmod 0700 ~/.ssh
    $ ssh-keygen -t dsa -f ~/.ssh/id_dsa
    {% endhighlight %}

    # Copie de la clé sur le serveur
    {% highlight bash %}
    $ scp ~/.ssh/id_dsa.pub user@ssh.alwaysdata.com:/home/user
    $ ssh user@ssh.alwaysdata.com
    user@ssh:~$ mkdir -p ~/.ssh
    user@ssh:~$ chmod 0700 ~/.ssh
    user@ssh:~$ cat id_dsa.pub >> ~/.ssh/authorized_keys
    user@ssh:~$ chmod 600 ~/.ssh/authorized_keys
    user@ssh:~$ rm id_dsa.pub
    {% endhighlight %}

Nous pouvons maintenant nous connecter sans mot de passe :

    {% highlight bash %}
    $ ssh user@ssh.alwaysdata.com
    {% endhighlight %}

Profitons d'être connectés pour créer le dépôt sur le serveur :

    {% highlight bash %}
    user@ssh:~$ mkdir -p git/monsite.git
    user@ssh:~$ cd git/monsite.git
    user@ssh:~/git/monsite$ git init --bare
    {% endhighlight %}

Nous venons de créer un dépôt vide prêt à recevoir notre code. Il nous faut maintenant indiquer dans notre dépôt local le chemin vers lequel envoyer le code sur le serveur. Ce dépôt distant est accessible en ssh à l'adresse `ssh://user@ssh.alwaysdata.com/home/user/git/monsite.git`. Nous ajoutons à notre dépôt local l'adresse du dépôt distant :

    {% highlight bash %}
    $ cd ~/Code/monsite
    $ git remote add origin ssh://user@ssh.alwaysdata.com/home/user/git/monsite.git
    {% endhighlight %}

Si nous tapons `git remote -v` nous voyons l'adresse du dépôt distant `origin` (appelé ainsi par convention). Il ne nous reste plus qu'à y envoyer notre code :

    {% highlight bash %}
    $ git push origin master
    {% endhighlight %}

Le site [ProGit][progit] propose un [chapitre sur les dépôts distants][progit-remote] pour en savoir plus. Notre code est maintenant accessible, nous pouvons passer à son déploiement avec Capistrano.

## Installation et configuration de Capistrano

Nous commençons par installer et versionner la gem Capistrano :

    # config/environment.rb
    {% highlight ruby %}
    config.gem 'capistrano', :lib => false
    {% endhighlight %}

    {% highlight bash %}
    $ sudo rake gems:install
    $ rake gems:unpack:dependencies
    $ git add .
    $ git commit -am "Ajout de Capistrano"
    {% endhighlight %}

Nous utilisons ici `:lib => false` pour indiquer que ces gems n'ont pas besoin d'être chargées au lancement du serveur de l'application. Elles ne sont utilisées qu'en local pour le déploiement, nous évitons d'alourdir la charge mémoire du serveur.

Nous préparons ensuite notre application à être déployée :

    {% highlight bash %}
    $ capify .
    {% endhighlight %}

Cette commande génère deux fichiers : `Capfile` et `config/deploy.rb`. `Capfile` permet à Capistrano de charger les fichiers contenant les tâches à effectuer pour le déploiement. `config/deploy.rb` va contenir les instructions de déploiement de notre site. Nous allons également créer un fichier `config/deploy/production.rb` qui va contenir les paramètres relatif à l'environnement.

    # config/deploy.rb
    {% highlight ruby %}
    set :user, "nom du user ssh"
    set :application, "monsite"
    set :branch, "master"
    set :domain, "ssh.alwaysdata.com"

    server domain, :app, :web
    role :db, domain, :primary => true
    set :runner, user

    ssh_options[:forward_agent] = true
    set :scm, :git
    set :repository, "ssh://user@ssh.alwaysdata.com/~/git/monsite.git"
    set :deploy_via, :remote_cache
    set :git_enable_submodules, 1
    set (:deploy_to) {"/home/user/rails/#{application}"}
    set :keep_releases, 5
    default_run_options[:pty] = true
    set :use_sudo, false

    after 'deploy:update_code' do
      run <<-CMD
        ln -nfs #{shared_path}/config/environments/production.rb #{release_path}/config/environments/production.rb
      CMD
      run <<-CMD
        ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml
      CMD
      %w(files sitemap.xml robots.txt dispatch.fcgi .htaccess).each do |file|
        run <<-CMD
          ln -nfs #{shared_path}/public/#{file} #{release_path}/public/#{file}
        CMD
      end
      run "cd #{release_path} ; rake RAILS_ENV=production gems:build"
    end
    after "deploy", "deploy:cleanup"
    after "deploy:migrations", "deploy:cleanup"

    namespace :deploy do
      task :cold do
        update
        load_schema
        start
      end

      task :load_schema, :roles => :app do
        run "cd #{current_path}; rake RAILS_ENV=production db:schema:load"
      end
    end

    deploy.task :start do
       # nothing
    end
    deploy.task :stop do
      # nothing
    end
    deploy.task :restart do
      # nothing
    end
    {% endhighlight %}

La première partie définit un ensemble de variables, je vous invite à consulter [la documentation des variables principales de Capistrano][doc-variables-capistrano] ainsi que [celle sur les rôles][doc-roles-capistrano] pour en savoir plus. Ici nous déployons sur un seul serveur sur lequel se trouve également le dépôt Git, la configuration est donc assez simple. Nous noterons parmi ces variables `repository`, `:deploy_to` et `:keep_releases`

- `:repository` indique où récupérer le code versionné
- `:deploy_to` indique le répertoire propre où sera déployé le code
- `:keep_releases` ici à 5 spécifie le nombre de versions du site que nous souhaitons conserver. Capistrano conserve les versions antérieures pour pouvoir revenir en arrière en cas de problème, il nous faut donc nettoyer les anciennes versions sous peine de voir notre espace complètement rempli au bout d'un certain nombre de déploiements.

La deuxième partie indique quoi faire à chaque étape du déploiement.

La tâche `after 'deploy:update_code'` est exécutée comme son nom l'indique une fois que le code a été récupéré depuis Git. Elle crée des liens symboliques vers des fichiers situés dans un répertoire `shared_path`. Pourquoi se donner cette peine ? Nous l'avons vu dans [l'article sur le démarrage d'une application avec Git][article-demarrage-appli], nous ne versionnons pas les fichiers contenant des données de configuration, seulement une version "exemple", ceci car :

- nous souhaitons éviter d'enregistrer dans Git des données sensibles comme les mots de passe
- nous ne souhaitons pas modifier le code versionné à chaque changement d'hébergement ou de configuration.

Nous allons donc devoir créer ces fichiers dans un répertoire spécial que Capistrano met à notre disposition. Il permet de stocker tous les fichiers qui ne sont pas versionnés mais dont l'application a besoin : fichiers de configuration, fichiers uploadés par les utilisateurs, etc. Nous y reviendrons dans un instant.

Nous lançons également à cette étape la compilation des gems avec `rake gems:build` au cas où certaines le nécessitent.

La tâche `after "deploy", "deploy:cleanup"` permet une fois le déploiement terminé de nettoyer les anciennes versions en ne gardant que le nombre indiqué pour `:keep_releases`.

Ensuite nous redéfinissons la tâche `cold` du namespace `deploy`. Celle-ci est exécutée pour le premier déploiement, nous lui faisons également charger la base de données à l'aide de la tâche rake `db:schema:load` avant de démarrer l'application.

Enfin les tâches `deploy.task :start`, `deploy.task :stop` et `deploy.task :restart` sont redéfinies vides car le redémarrage du serveur n'est pour le moment pas possible en ligne de commande chez Alwaysdata. Ce n'est pas très grave car il est facile de le faire depuis la console d'administration, l'équipe a de plus prévu de le rendre possible en ligne de commande par la suite.

Il ne nous reste plus qu'à paramétrer les répertoires nécessaires sur le serveur et vérifier que tout est bien en place avant le déploiement. Capistrano fournit pour cela deux tâches `setup` et `check` très pratiques que nous exécutons :

    {% highlight bash %}
    $ cap deploy:setup
    $ cap deploy:check
    {% endhighlight %}

Elles permettent de créer les répertoires nécessaires au fonctionnement de Capistrano et de vérifier que tout est installé correctement.

## Paramétrage sur le serveur

Tout est prêt sur notre poste, il nous reste à créer sur le serveur les divers fichiers de configuration et répertoires partagés de notre application. Nous commençons par nous connecter au serveur et regardons ce qui a été créé par Capistrano :

    {% highlight bash %}
    $ ssh user@ssh.alwaysdata.com
    user@ssh:~$ ls rails
    monsite
    user@ssh:~$ cd rails/monsite
    user@ssh:~/rails/monsite$ ls
    releases shared
    user@ssh:~/rails/monsite$ ls shared
    log pids system
    {% endhighlight %}

Le répertoire `releases` va contenir les différentes version de notre application. Une fois déployée, un lien symbolique `current` pointant vers la version actuelle sera créé. À chaque nouveau déploiement, un nouveau répertoire sera créé dans `releases` et `current` sera modifié pour pointer sur la nouvelle version.

Le répertoire `shared` est utilisé pour stocker tous les fichiers conservés à chaque déploiement, comme les fichiers de logs. Nous avons vu dans `config/deploy.rb` une référence à une variable `shared_path`, elle correspond à ce répertoire. Nous y créons les répertoires nécessaires :

    {% highlight bash %}
    user@ssh:~$ cd ~/rails/monsite/shared
    user@ssh:~/rails/monsite/shared$ mkdir public
    user@ssh:~/rails/monsite/shared$ mkdir -p config/environments
    {% endhighlight %}

Il nous faut maintenant créer dans le répertoire `shared` de chaque environnement un certain nombre de fichiers dont voici la liste :

- `config/database.yml` : la configuration de la base de données
- `config/environments/production.rb` : la configuration de l'environnement
- `public/.htaccess` : pour rediriger les requêtes sur le processus FCGI
- `public/dispatch.fcgi` : nous allons en utiliser une version paramétrée pour Alwaysdata

Voici ci-dessous le contenu de chaque fichier, à saisir soit directement en éditant les fichiers sur le serveur avec un éditeur comme vi, soit en les copiant par SFTP.

Il faut également créer dans la console d'administration la base de données.

    # config/database.yml
    {% highlight yaml %}
    production:
      adapter: mysql
      database: base
      host: mysql.alwaysdata.com
      username: login
      password: password
      encoding: utf8
    {% endhighlight %}

    # config/environments/production.rb
    {% highlight ruby %}
    config.cache_classes = true

    config.action_controller.consider_all_requests_local = false
    config.action_controller.perform_caching             = true
    config.action_view.cache_template_loading            = true

    config.action_mailer.default_url_options = {
      :host => 'www.monsite.com'
    }
    ActionMailer::Base.delivery_method = :smtp
    ActionMailer::Base.smtp_settings = {
      :address => "smtp.alwaysdata.com",
      :port => 25,
      :domain => "alwaysdata.net",
      :authentication => :login,
      :user_name => "login@alwaysdata.net",
      :password => "password"
    }
    {% endhighlight %}

    # public/.htaccess
    {% highlight apacheconf %}
    AddHandler fcgid-script .fcgi
    AddHandler cgi-script .cgi
    Options +FollowSymLinks +ExecCGI

    RewriteEngine On

    RewriteRule ^$ index.html [QSA]
    RewriteRule ^([^.]+)$ $1.html [QSA]
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteRule ^(.*)$ dispatch.fcgi [QSA,L]

    ErrorDocument 500 "<h2>Application error</h2>Rails application failed to start properly"
    {% endhighlight %}

    # public/dispatch.fcgi
    {% highlight ruby %}
    #!/usr/bin/env ruby

    ENV['RAILS_ENV'] = 'production'
    require File.dirname(__FILE__) + "/../config/environment"
    require 'fcgi_handler'
    RailsFCGIHandler.process!
    {% endhighlight %}

Dans `dispatch.fcgi`, nous ajoutons `ENV['RAILS_ENV'] = 'production'` pour définir avant le chargement de l'application l'environnement dans lequel elle doit s'exécuter.

Pour le mot de passe de la base de données, dans la console d'administration :

1. cliquer sur "MySQL" dans la partie "Base de données"
2. cliquer sur "Gestion des utilisateurs"
3. cliquer sur "Modifier" sur l'utilisateur du même nom que le pack
4. modifier le mot de passe et le reporter dans le fichier `config/database.yml`

Pour le mot de passe des emails, dans la console d'administration :

1. cliquer sur "Emails"
2. cliquer sur "Modifier" sur l'utilisateur du même nom que le pack dans la partie "alwaysdata.net"
3. modifier le mot de passe et le reporter dans le fichier `config/environments/production.rb`

Une fois ces fichiers créés, il faut rendre le fichier `dispatch.fcgi` exécutable :

    {% highlight bash %}
    user@ssh:~$ chmod +x /home/login/rails/monsite/shared/public/dispatch.fcgi
    {% endhighlight %}

## Déploiement de l'application

Tout est prêt, nous pouvons lancer le premier déploiement depuis notre poste :

    {% highlight bash %}
    cap deploy:cold
    {% endhighlight %}

Cela prend un peu de temps car tout est initialisé pour la première fois ; les déploiements suivants seront plus rapides.

Pour accéder à notre site il faut maintenant faire pointer le domaine sur le répertoire `public` de l'environnement. Pour cela, nous nous rendons dans la console d'administration dans la rubrique "Domaines". Si un domaine est enregistré, il faut faire pointer `www` sur `/rails/monsite/current/public`. Si aucun domaine n'est installé, il faut faire pointer le domaine `nomdupack.alwaysdata.net` sur `/rails/monsite/current/public`.

Nous pouvons alors nous rendre sur le site, et si tout s'est bien passé nous devrions voir la page d'accueil de notre application.

En cas d'erreur, une première piste est de se connecter au serveur en ssh et de lancer le fichier `dispatch.fcgi` pour voir si une erreur se produit :

    {% highlight bash %}
    user@ssh:/rails/monsite/current/public$ ./dispatch.fcgi
    {% endhighlight %}

Les erreurs FCGI sont également enregistrées dans `shared/log/fastcgi.crash.log`. Les autres erreurs sont enregistrées dans le fichier `shared/log/production.log`.

## Et ensuite ?

Tout ceci semble peut-être représenter un gros travail pour une "simple" mise en ligne, mais les avantages sont déjà nombreux. Lors d'une mise à jour, il n'y a plus de risque d'oublier un fichier lors de grosses mises à jour ou de risquer qu'un visiteur se rende sur le site et rencontre une erreur.

Les déploiements suivants se font de manière très simple et entièrement automatique :

    {% highlight bash %}
    $ git push origin master
    $ cap deploy
    {% endhighlight %}

Lorsque par la suite des migrations ont eu lieu, il suffit de lancer `cap deploy:migrations` au lieu de `cap deploy` et elles seront appliquées sur la base en ligne. En cas d'erreur, `cap deploy:rollback` permet de revenir en arrière.

La seule chose qui reste aujourd'hui manuelle est le redémarrage du processus FCGI dans la console d'administration à la rubrique "Avancé > Processus" en cliquant sur "Terminer tous". Lorsque le redémarrage sera possible en ligne de commande, il suffira de modifier la tâche `deploy.task :restart`.

Cette méthode est une base pouvant être améliorée en fonction des besoins. Par exemple, nous avons utilisé dans `config/deploy.rb` plusieurs liens symboliques qui seront vraisemblablement réutilisés pour chaque nouvelle application. Nous pouvons donc envisager de les regrouper dans un plugin versionné à part que nous incluerons ensuite dans nos applications pour en simplifier le déploiement. De même, une tâche s'occupant de créer les répertoires et fichiers dans `shared` serait un ajout utile à ce plugin. Avec quelques petites modfications, il est facile de déployer sur plusieurs environnements pour avoir également un site de test permettant la validation de modifications par le client avant leur passage en production. Ces sujets feront l'objet de prochains articles.

[alwaysdata]: http://www.alwaysdata.com
[capistrano]: http://github.com/capistrano/capistrano
[wiki-cle-publique]: http://wiki.alwaysdata.com/wiki/Se_connecter_en_SSH_avec_sa_clé_publique
[doc-variables-capistrano]: http://wiki.github.com/capistrano/capistrano/significant-configuration-variables
[doc-roles-capistrano]:http://wiki.github.com/capistrano/capistrano/roles
[article-demarrage-appli]:/articles/demarrer-une-nouvelle-application-rails-avec-git-et-un-modele
[progit-remote]:http://progit.org/book/ch2-5.html
[progit]:http://progit.org/book/