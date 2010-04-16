---
layout: post
title: Définir des paramètres de configuration avec SettingsLogic
category: configuration
auteur: Matthieu Sadouni
chapo: Rails a pour principe d'éviter la configuration au profit de conventions, mais il arrive toujours un moment où nous avons besoin de configurer quelques paramètres d'une application. Voyons comment réaliser cela de manière très simple avec SettingsLogic.
description: |
  Comment définir paramètres de configuration avec SettingsLogic.
---

## Présentation de SettingsLogic

[SettingsLogic][settingslogic-github] est une gem permettant d'accéder par l'intermédiaire d'une classe au contenu d'un fichier de configuration au format YAML. Dans ce dernier, nous allons définir tous les paramètres dont nous avons besoin en fonction de chaque environnement, comme par exemple l'adresse email d'expédition des message envoyés par le site. La valeur correspondante à l'environnement en cours sera ensuite disponible dans notre application.

## Installation

Nous ajoutons au fichier `config/environment.rb` la gem SettingsLogic, dépaquetons le code et versionnons le tout :

    # config/environnement.rb
    {% highlight ruby %}
    config.gem 'settingslogic'
    {% endhighlight %}

    {% highlight bash %}
    $ sudo rake gems:install
    $ rake gems:unpack:dependencies
    $ git add .
    $ git commit -am "SettingsLogic"
    {% endhighlight %}

## Configuration

Nous commençons par créer la classe `Settings` nous permettant d'accéder aux différents paramètres :

    # app/models/settings.rb
    {% highlight ruby %}
    class Settings < SettingsLogic
      source "#{Rails.root}/config/application.yml"
      namespace Rails.env
      load!
    end
    {% endhighlight %}

Nous voyons ici que le fichier de paramétrage est lu, puis les paramètres sont chargés en fonction de l'environnement dans lequel est exécutée l'application.

Nous créons ensuite deux versions de ce fichier. L'une `application.yml.default` sera versionnée, l'autre `application.yml` ignorée. Cela permet à chaque développeur de définir les paramètres en fonction de son environnement de travail, et de ne pas versionner les paramètres utilisés en production (cf. [l'article sur le déploiement avec Capistrano][article-capistrano]).

    # config/application.yml.default
    {% highlight yaml %}
    defaults: &defaults
      emails:
        contact: contact@example.com
        from: no-reply@example.com
      par_page: 10
      dynamique: <%= 1 + 2 %>

    development:
      <<: *defaults
      par_page: 20

    test:
      <<: *defaults

    production:
      <<: *defaults
    {% endhighlight %}

    # config/application.yml
    {% highlight yaml %}
    defaults: &defaults
      emails:
        contact: contact@monsite.com
        from: no-reply@monsite.com
      par_page: 10

    development:
      <<: *defaults
      par_page: 20

    test:
      <<: *defaults

    production:
      <<: *defaults
    {% endhighlight %}

Nous voyons ici que SettingsLogic est flexible, il permet de définir des paramètres imbriqués, d'utiliser ERB, etc.

Nous ajoutons au fichier `.gitignore` le fichier de configuration :

    # .gitignore
    {% highlight bash %}
    config/application.yml
    {% endhighlight %}

Puis nous versionnons la classe Settings et les paramètres par défaut :

    {% highlight bash %}
    $ git add .
    $ git commit -am "Configuration par défaut"
    {% endhighlight %}

## Accès aux paramètres

Nous pouvons maintenant accéder aux paramètres de configuration dans l'application. Par exemple, pour utiliser les emails dans un formulaire de contact :

    # app/models/contact_mailer.rb
    {% highlight ruby %}
    class ContactMailer < ActionMailer::Base
        def contact(contact)
          subject "Nouveau contact"
          from Settings.emails.from
          recipients Settings.emails.contact
          sent_on Time.now
          body :contact => contact
        end
    end
    {% endhighlight %}

L'email de contact aura pour expéditeur et destinataire les emails correspondants définis dans le fichier de paramétrage. SettingsLogic permet également de donner une valeur par défaut si un paramètre n'est pas défini :

    {% highlight ruby %}
    par_page = Settings.pagination['articles_par_page'] ||= 10
    {% endhighlight %}

Ici `par_page` aura pour valeur `10` car `articles_par_page` n'est pas défini dans les paramètres.

[settingslogic-github]:http://github.com/binarylogic/settingslogic
[article-capistrano]:/articles/mettre-en-ligne-un-site-chez-alwaysdata-avec-git-et-capistrano