---
layout: post
title: Créer et envoyer un email
category: interaction, email
auteur: Matthieu Sadouni
chapo: Ruby on Rails utilise ActionMailer pour la gestion des emails. Voyons comment créer et envoyer un email au format texte et HTML, ainsi que quelques astuces pour en simplifier la gestion.
description: |
  Comment créer et envoyer des emails texte et HTML avec Ruby on Rails.
---

## Principe

Le framework Ruby on Rails est construit sur le principe [MVC][mvc-wikipedia], et les emails n'échappent pas à cette règle. Ils sont gérés par des modèles un peu particuliers qui héritent de `ActionMailer::Base`, les `Mailer`. Chaque `Mailer` concerne une partie de l'application, par exemple :

- `UserMailer` pour les emails en rapport avec l'inscription et l'activation de compte
- `PostMailer` pour les emails de notification d'un nouvel article aux abonnés
- `OrderMailer` pour les emails de notification des différentes étapes d'avancement d'une commande

Dans chaque `Mailer`, une méthode de classe est définie pour chaque email. Y sont définis le destinataire, le sujet, les variables utilisées dans le corps du message, etc. Le message final est compilé à partir d'une vue, comme n'importe quelle action de contrôleur dans l'application.

## Création d'un Mailer

Un script fourni avec Ruby on Rails permet de générer les fichiers nécessaires :

    {% highlight bash %}
    $ script/generate mailer user_mailer
    {% endhighlight %}

Intéressons-nous tout d'abord au fichier `models/user_mailer.rb`, auquel nous ajoutons une méthode représentant un email de bienvenue après l'inscription :

    # app/models/user_mailer.rb
    {% highlight ruby %}
    class UserMailer < ActionMailer::Base
      def bienvenue(user)
        recipients user.email
        from "Example.com<no-reply@example.com>"
        subject "Bienvenue !"
        body :user => user, :account_url => edit_user_url(user)
      end
    end
    {% endhighlight %}

- `recipients` définit le destinataire à partir d'une chaîne contenant une adresse email, ou un tableau de chaînes (sous forme `['email1@example.com', 'John<john@example.com>]`)
- `from` définit l'adresse de l'expéditeur
- `subject` définit, sans surprise, le sujet
- `body` permet de définir des variables accessibles dans la vue

La liste complète des attributs est disponible [dans le chapitre 2.3 du guide ActionMailer (en anglais)][guide-actionmailer]. Les plus utilisés, à part ceux présentés ici, sont probablement `bcc` et `reply-to`.

Nous voyons ici que l'une des variables accessibles dans la vue, `account_url`, contient l'url du compte de l'utilisateur. Les `Mailers` n'ayant pas accès au contexte de la requête, il faut paramétrer l'URL de base de l'application pour que le lien complet puisse être construit. Nous ajoutons pour cela une ligne au fichier de l'environnement concerné :

    # config/environments/<environment>.rb
    {% highlight ruby %}
    config.action_mailer.default_url_options = {:host => "example.com"}
    {% endhighlight %}

Avec pour `:host` le nom du domaine sur lequel est hébergé l'application. En développement, ce sera par exemple `localhost:3000`.

Il ne nous reste plus qu'à créer la vue correspondante :

    # app/views/user_mailer/bienvenue.text.plain.erb

    {% highlight erb %}
    Bienvenue <%= @user %> !
    Votre compte : <%= @account_url %>
    {% endhighlight %}

Notons que le nom du fichier mentionne le type de format utilisé (`text.plain`). Nous y reviendrons juste après le chapitre suivant.

## Envoi d'un email

Une fois l'email créé, le plus simple pour l'envoyer est d'appeler la méthode correspondante dans un contrôleur :

    # app/controllers/users_controller.rb
    {% highlight ruby %}
    class UsersController < ApplicationController
      def create
        @user = User.new(params[:user])
        if @user.save
          UserMailer.deliver_bienvenue(@user)
          redirect_to root_path and return
        end
      end
    end
    {% endhighlight %}

Nous remarquons que la méthode appelée est `deliver_bienvenue` et non `bienvenue`. ActionMailer utilise `method_missing` [(en savoir plus sur `method_missing` - en anglais)][explications-method-missing] pour retrouver la méthode demandée `bienvenue` et envoyer l'email. Il est ainsi également possible de créer notre email sans l'envoyer, via `create_bienvenue`. Ceci permet de n'écrire qu'une seule méthode pour définir un email, et de l'envoyer en une seule ligne de code. De plus, le code dans le contrôleur est plus lisible car l'intention est claire :

    {% highlight ruby %}
    UserMailer.deliver_bienvenue(user)
    # est plus explicite que
    UserMailer.bienvenue(user)
    {% endhighlight %}

Il existe deux autres manières d'envoyer un email. La première, depuis un modèle, par exemple ici dans la méthode `after_create` :

    # app/models/user.rb
    {% highlight ruby %}
    class User < ActiveRecord::Base
      after_create :notify_by_email

      private
        def notify_by_email
          UserMailer.deliver_bienvenue(self)
        end
    end
    {% endhighlight %}

Le souci avec cette approche est que du code sans rapport avec la responsabilité première du modèle lui est rajouté. Pour éviter cela, nous pouvons utiliser un `Observer`. Comme son nom l'indique, un `Observer` "observe" une classe et répond aux méthodes de rappel (callbacks) comme `after_create`, `before_save` etc. Pour mettre en place ce fonctionnement, nous commençons par créer un fichier `app/models/user_observer.rb` :

    # app/models/user_observer.rb
    {% highlight ruby %}
    class UserObserver < ActiveRecord::Observer
      def after_save(user)
        UserMailer.deliver_bienvenue(user)
      end
    end
    {% endhighlight %}

Pour que l'`Observer` soit chargé automatiquement au lancement de l'application, il faut le spécifier dans `config/environment.rb` :

    # config/environment.rb
    {% highlight ruby %}
    Rails::Initializer.run do |config|
      ...
      config.active_record.observers = :user_observer
    end
    {% endhighlight %}

Il ne reste plus ensuite qu'à supprimer de `UsersController` la ligne concernant l'envoi de l'email, celui-ci étant envoyé automatiquement par l'`Observer` après la création de l'utilisateur :

    # app/controllers/users_controller.rb
    {% highlight ruby %}
    class UsersController < ApplicationController
      def create
        @user = User.new(params[:user])
        if @user.save
          redirect_to root_path and return
        end
      end
    end
    {% endhighlight %}

Chaque méthode a ses avantages et ses inconvénients. Un `Observer` permet de garder le code du modèle et du contrôleur le plus simple possible, et de s'assurer que l'email est envoyé à chaque fois qu'un utilisateur est créé, même sans passer par le contrôleur (en console par exemple). Par contre, si l'application grossit et compte plusieurs observers réalisant chacun plusieurs tâches, il peut être difficile de bien voir tout ce qu'il se passe sur une action donnée.

L'envoi depuis le contrôleur ou un modèle permet quant à lui de garder un code plus clair, car chaque action effectuée est directement visible, en contrepartie de la possibilité d'une duplication de code. C'est à chacun de choisir la méthode appropriée selon ses besoins, en gardant à l'esprit que les deux approches sont compatibles.

## Envoi au format HTML

L'envoi au format HTML est très simple : il suffit d'avoir deux vues du même nom que l'email, une pour la version texte et une pour la version HTML :

    # app/views/user_mailer/bienvenue.text.plain.erb
    {% highlight erb %}
    Bienvenue <%= @user %> !
    
    Votre compte : <%= @account_url %>
    {% endhighlight %}

    # app/views/user_mailer/bienvenue.text.html.erb
    {% highlight erb %}
    <h1>Bienvenue <%= @user %> !</h1>
    
    <p><a href="<%= @account_url %>">Votre compte</a></p>
    {% endhighlight %}

Rails va alors automatiquement construire un email au format multipart, sans aucune autre action nécessaire de notre part.

## Utiliser un layout

Comme un contrôleur, un `Mailer` peut également utiliser un layout pour ses vues. Il suffit pour cela de créer un fichier dont le nom se termine par `_mailer` et nommé comme le `Mailer`. Pour `UserMailer`, les layouts `app/views/layouts/user_mailer.text.plain.erb` et `app/views/layouts/user_mailer.text.html.erb` seront automatiquement utilisés. Pour spécifier un autre fichier, il faut utiliser la méthode `layout` :

    # app/models/user_mailer.rb
    {% highlight ruby %}
    class UserMailer < ActionMailer::Base
      layout 'application_mailer'
    end
    {% endhighlight %}

    # app/views/layouts/application_mailer.text.plain.erb
    {% highlight erb %}
    <%= yield %>
    --
    À bientôt sur notre site
    Toute l'équipe de http://www.example.com
    {% endhighlight %}

Le layout HTML, nécessaire si une vue existe au format HTML, serait quant à lui nommé `application_mailer.text.html.erb`.

## Optimiser ses Mailers

À partir du moment où l'application utilise plusieurs `Mailers`, du code se retrouve dupliqué lors du paramétrage des emails :

- les attributs `from` et `sent_on` sont quasiment toujours identiques
- si un seul layout est utilisé pour tous les `Mailers`, il est nécessaire de le définir dans chacun puisque le fonctionnement automatique en fonction du nom du `Mailer` n'est plus possible
- si nous souhaitons ajouter le nom de l'application entre crochets devant le sujet de chaque message pour faciliter le filtrage des emails, il faudrait le répéter dans chaque méthode de nos `Mailers`

Pour remédier à cela, nous créons une classe `ApplicationMailer` dont héritent les `Mailers` de l'application. Nous y centralisons le code commun dans une méthode `setup` et allégeons ainsi nos `Mailers` :

    # app/models/application_mailer.rb
    {% highlight ruby %}
    class ApplicationMailer < ActionMailer::Base
      layout 'application_mailer'

      protected
        def setup(*args)
          from "Example.com<no-reply@example.com>"
          subject "[Example.com] "
          sent_on Time.now
        end
    end
    {% endhighlight %}

Il nous suffit ensuite de faire hériter `UserMailer` de `ApplicationMailer` et d'appeler la méthode `setup` :

    # app/models/user_mailer.rb
    {% highlight ruby %}
    class UserMailer < ApplicationMailer
      def bienvenue(user)
        setup
        recipients user.email
        @subject += "Bienvenue !"
        body :user => user, :account_url => edit_user_url(user)
      end
    end
    {% endhighlight %}

Notons l'utilisation de `@subject` pour ajouter au sujet prédéfini dans `setup` le sujet de l'email.

Une autre forme de duplication apparaît également dans chaque `Mailer`, selon sa responsabilité. Par exemple, les emails de notre `UserMailer` sont presque toujours envoyé à un utilisateur passé en paramètre. Celui-ci est également passé à leur vue respective pour y afficher son nom, etc. Pour centraliser cela, nous surchargeons la méthode `setup` dans chaque Mailer concerné :

    # app/models/user_mailer.rb
    {% highlight ruby %}
    class UserMailer < ApplicationMailer
      ...
      def bienvenue(user)
        setup(user)
        @subject += "Bienvenue !"
        body[:account_url] = edit_user_url(user)
      end

      def anniversaire(user)
        setup(user)
        @subject += "Joyeux anniversaire !"
      end

      def anonyme
        setup
        recipients ["test@example.com", "test2@example.com"]
        @subject += "Un simple exemple n'utilisant pas user"
      end

      protected
        def setup(user = nil)
          super
          if user
            recipients user.email
            body :user => user
          end
        end
    end
    {% endhighlight %}

Notons l'utilisation de `body[:account_url]` pour ajouter une variable disponible dans la vue.

Nous venons de voir les bases de l'utilisation d'ActionMailer, couvrant les principaux besoins d'une application web en terme de création et d'envoi d'emails. ActionMailer propose également d'autres fonctionnalités comme la réception d'emails ou l'attachement de pièces jointes sur lesquelles nous reviendrons dans un prochain article.

[mvc-wikipedia]:http://fr.wikipedia.org/wiki/Modèle-Vue-Contrôleur
[guide-actionmailer]:http://guides.rubyonrails.org/action_mailer_basics.html
[explications-method-missing]:http://weblog.jamisbuck.org/2006/12/1/under-the-hood-activerecord-base-find-part-3