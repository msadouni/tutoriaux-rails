---
layout: post
title: Traduire les messages et les dates en français
category: interaction
auteur: Matthieu Sadouni
chapo: |
  Rails est par défaut configuré en langue anglaise. Depuis la version 2.2 il est devenu très simple de traduire les messages du cœur comme les dates et les messages d'erreur. Voyons comment intégrer les traductions en français à notre application.
description: |
  Comment traduire les messages d'erreur et les dates du cœur de Rails en français.
---

### Récupération des traductions depuis GitHub

Rails utilise un système basé sur un fichier YAML ou ruby contenant les traductions de toutes les chaînes du cœur. Des traductions dans un grand nombre de langues dont le français sont disponibles dans un dépôt Git disponible sur GitHub. Nous commençons par cloner ce dépôt pour pouvoir facilement récupérer les mises à jour par la suite.

    {% highlight bash %}
    cd ~/Code # ou tout autre répertoire de votre choix
    git clone git://github.com/svenfuchs/rails-i18n.git
    {% endhighlight %}

Si vous ne disposez pas de Git, des explications pour l'installer sont disponibles pour [Mac OS X][git-osx], [Windows][git-windows] et [Linux Ubuntu][git-linux].

Si nous regardons le code que nous venons de cloner, nous trouvons l'ensemble des traductions dans le répertoire `rails/locale`. Nous copions le fichier `fr.yml` qui nous intéresse dans le répertoire `config/locales` de notre application.

### Configuration de l'application

Il nous faut maintenant indiquer à Rails que la locale par défaut est le français. Il nous suffit pour cela de modifier une ligne se trouvant à la fin du fichier `config/environment.rb` :

    {% highlight ruby%}
    config.i18n.default_locale = :fr
    {% endhighlight %}

Une fois le serveur relancé, les messages et dates s'affichent en français. Simple, non ?

[git-osx]: /articles/installation-d-un-environnement-de-developpement-rails-sur-mac-os-x
[git-windows]: /articles/installation-d-un-environnement-de-developpement-sur-windows-xp
[git-linux]: /articles/installation-d-un-environnement-de-developpement-sur-linux-ubuntu
