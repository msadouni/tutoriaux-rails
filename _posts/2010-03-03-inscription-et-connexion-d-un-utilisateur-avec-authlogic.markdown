---
layout: post
title: Inscription et connexion d'un utilisateur avec Authlogic
category: authentification
auteur: Matthieu Sadouni
chapo: La gestion d'utilisateurs est une tâche récurrente, sinon systématique lors du développement d'une application Web. Nous allons voir comment utiliser le plugin Authlogic pour faciliter cette tâche.
description: |
  Comment installer et configurer Authlogic pour permettre l'inscription et la connexion d'un utilisateur.
---

[Authlogic][authlogic] est une solution simple et élégante pour gérer l'inscription et la connexion d'utilisateurs. Voyons comment l'intégrer à un site existant.

### Installation

Nous commençons par indiquons dans `config/environment.rb` que notre application utilise la gem Authlogic :

    # config/environment.rb
    
    {% highlight ruby %}
    Rails::Initializer.run do |config|
      # ...
      config.gem 'authlogic', :source => 'http://gemcutter.org'
      # ...
    end
    {% endhighlight %}

Nous installons ensuite la gem et décompressons son code dans le répertoire `vendor/gems` :

    {% highlight bash %}
    sudo rake gems:install
    rake gems:unpack:dependencies
    {% endhighlight %}

Nous paramétrons ensuite notre application pour Authlogic. Une [application exemple][authlogic-exemple] avec les instructions d'installation et des explications est disponible sur github. Nous en reprenons ici les différentes étapes.

### Création du modèle UserSession

Authlogic permet de gérer des sessions gérées comme un modèle ActiveRecord. Elles peuvent êtres créées et détruites par un controller RESTful que nous allons créer par la suite. Nous créons le modèle `UserSession` grâce au générateur fourni :

    {% highlight bash %}
    script/generate session user_session
    {% endhighlight %}

Un fichier `app/models/user_session.rb` est créé et contient le code suivant :

    {% highlight ruby %}
    class UserSession < Authlogic::Session::Base
    end
    {% endhighlight %}

Nous ajoutons enfin une route pour la création et destruction de la session :

    # config/routes.rb

    {% highlight ruby %}
    map.resource :user_session
    {% endhighlight %}

### Création du modèle User

Avoir une gestion des sessions est pratique, mais encore faut-il avoir des utilisateurs à authentifier ! Créons un modèle User :

    {% highlight bash %}
    script/generate model user
    {% endhighlight %}

Plusieurs fichiers sont créés, dont un fichier de migration qui va nous servir à créer la table en base de données. Nous éditons ce fichier situé dans `db/migrate` pour ajouter les colonnes nécessaires au fonctionnement d'Authlogic :

    # db/migrate/xxxxxxxxxxxxxx_create_users.rb

    {% highlight ruby %}
    class CreateUsers < ActiveRecord::Migration
      def self.up
        create_table :users do |t|
          t.string :email, :null => false
          t.string :crypted_password, :null => false
          t.string :password_salt, :null => false
          t.string :persistence_token, :null => false
          t.string :perishable_token, :null => false
          t.integer :login_count, :null => false, :default => 0
          t.integer :failed_login_count, :null => false, :default => 0
          t.datetime :last_request_at
          t.datetime :current_login_at
          t.datetime :last_login_at
          t.string :current_login_ip
          t.string :last_login_ip
          t.timestamps
        end
      end

      def self.down
        drop_table :users
      end
    end
    {% endhighlight %}

Chacun des choix faits ici est configurable ou modifiable, Authlogic permettant une grande souplesse à ce niveau. Voyons à quoi sert chaque champ :

- l'email de l'utilisateur est utilisé comme login.
- `crypted_password` et `password_salt` sont utilisés pour le cryptage et le stockage du mot de passe
- `persistence_token` sert à maintenir l'utilisateur connecté
- `perishable_token` est utilisé pour identifier un utilisateur lors de la confirmation de son ouverture de compte et de la réinitialisation de son mot de passe.
- `login_count` sert à stocker le nombre de fois où l'utilisateur s'est connecté
- `failed_login_count` est utilisé pour la protection contre les attaques "brute force" (par défaut Authlogic suspend un utilisateur pour 2 heures au bout de 50 essais infructueux, ces valeurs étant bien sûr configurables.)
- `last_request_at` sert à stocker la date de dernière action sur le site
- `current_login_at` sert à stocker la date de dernière connexion
- `last_login_at` sert à stocker la valeur de `current_login_at` avant qu'il ne soit réinitialisé
- `current_login_ip` sert à stocker l'adresse IP de dernière connexion
- `last_login_ip` sert à stocker la valeur de `current_login_ip` avant qu'il ne soit réinitialisé

Nous pouvons maintenant mettre à jour la base de données avec la migration :

    {% highlight bash %}
    rake db:migrate
    {% endhighlight %}

### Configuration du modèle User

Nous allons maintenant indiquer qu'un utilisateur est identifié par Authlogic. Il suffit d'ajouter une ligne au modèle `User` :

    # app/models/user.rb

    {% highlight ruby %}
    class User < ActiveRecord::Base
      acts_as_authentic
    end
    {% endhighlight %}

Pour le moment nous conservons la configuration par défaut. Par la suite il sera facile de rajouter des options de configuration dans un bloc :

    # app/models/user.rb

    {% highlight ruby %}
    class User < ActiveRecord::Base
      acts_as_authentic do |c|
        c.config_option = config_value
      end
    end
    {% endhighlight %}

La [documentation d'Authlogic][doc-authlogic] donne la liste des options disponibles pour chaque module dans `Authlogic::ActsAsAuthentic::<module>::Config`.

### Inscription des utilisateurs

Nos modèles sont prêts, nous pouvons démarrer la réalisation des différentes actions. Nous allons commencer par permettre aux utilisateurs de s'inscrire. Nous créons tout d'abord un contrôleur `UsersController` :

    {% highlight bash %}
    script/generate controller users
    {% endhighlight %}

Nous y ajoutons les actions REST `new` et `create` :

    # app/controllers/users_controller.rb

    {% highlight ruby %}
    class UsersController < ApplicationController

      def new
        @user = User.new
      end

      def create
        @user = User.new(params[:user])
        if @user.save
          flash[:notice] = "Votre compte a bien été créé"
          redirect_to '/'
        else
          render :action => :new
        end
      end

    end
    {% endhighlight %}

Nous créons ensuite la vue correspondante :

    # app/views/users/new.html.erb

    {% highlight erb %}
    <h1>Créer un compte</h1>

    <% form_for @user do |f| %>
      <%= f.error_messages %>
      <div>
        <%= f.label 'Email' %>
        <%= f.text_field :email %>
      </div>
      <div>
        <%= f.label 'Mot de passe' %>
        <%= f.password_field :password %>
      </div>
      <div>
        <%= f.label 'Confirmer le mot de passe' %>
        <%= f.password_field :password_confirmation %>
      </div>
      <%= f.submit "Créer mon compte" %>
    <% end %>
    {% endhighlight %}

Nous ajoutons la route correspondante aux actions REST sur `UsersController` :

    # config/routes.rb

    {% highlight ruby %}
    ActionController::Routing::Routes.draw do |map|
      map.resources :users
    end
    {% endhighlight %}

Nous pouvons maintenant nous rendre sur `http://localhost:3000/users/new` et remplir le formulaire d'inscription. Une fois inscrit, nous lançons la console pour vérifier que l'utilisateur est bien enregistré :

    {% highlight bash %}
    script/console
    y User.last
    {% endhighlight %}

Nous voyons les informations de notre utilisateur s'afficher, nous pouvons maintenant nous intéresser à sa connexion.

### Connexion et déconnexion des utilisateurs

Une fois l'utilisateur créé, nous devons lui permettre de se connecter. Nous commençons par créer une page d'accueil sur laquelle nous verrons :

- un lien vers le formulaire de connexion si l'utilisateur n'est pas connecté
- l'email de l'utilisateur connecté sinonNous créons pour cela un contrôleur

Nous ajoutons tout d'abord une route pour la page d'accueil :

    # config/routes.rb

    {% highlight ruby %}
    ActionController::Routing::Routes.draw do |map|
      map.root :controller => :users, :action => :index
      map.resources :users
    end
    {% endhighlight %}

ainsi que deux méthodes `current_user` et `current_user_session` à `ApplicationController` :

    # app/controllers/application_controller.rb

    {% highlight ruby %}
    class ApplicationController < ActionController::Base
      helper :all # include all helpers, all the time
      protect_from_forgery # See ActionController::RequestForgeryProtection for details

      filter_parameter_logging :password, :password_confirmation
      helper_method :current_user_session, :current_user

      private
        def current_user_session
          return @current_user_session if defined?(@current_user_session)
          @current_user_session = UserSession.find
        end

        def current_user
          return @current_user if defined?(@current_user)
          @current_user = current_user_session && current_user_session.user
        end
    end
    {% endhighlight %}

Nous ajoutons ensuite une action `index` à notre contrôleur `UsersController` :

    # app/controllers/users_controller.rb

    {% highlight ruby %}
    class UsersController < ApplicationController

      def index

      end

      def new
        @user = User.new
      end

      def create
        @user = User.new(params[:user])
        if @user.save
          flash[:notice] = "Votre compte a bien été créé"
          redirect_to '/'
        else
          render :action => :new
        end
      end

    end
    {% endhighlight %}

Puis nous créons la vue correspondante :

    # app/views/users/index.html.erb

    {% highlight erb %}
    <h1>Bienvenue</h1>
    <% if current_user %>
      <p><%= current_user.email %></p>
      <%= link_to "Déconnexion", user_session_path, :method => :delete %>
    <% else %>
      <p><%= link_to "Connexion", new_user_session_path %></p>
      <p><%= link_to "S'inscrire", new_user_path %></p>
    <% end %>
    {% endhighlight %}

Nous créons maintenant le contrôleur `UserSessions` qui va gérer la création et la suppression de sessions :

    {% highlight bash %}
    script/generate controller user_sessions new create destroy
    {% endhighlight %}

Nous y ajoutons le code classique d'un contrôleur RESTful :

    # app/controllers/user_sessions_controller.rb

    {% highlight ruby %}
    class UserSessionsController < ApplicationController

      def new
        @user_session = UserSession.new
      end

      def create
        @user_session = UserSession.new(params[:user_session])
        if @user_session.save
          flash[:notice] = "Vous êtes maintenant connecté"
          redirect_to root_path
        else
          render :action => :new
        end
      end

      def destroy
        current_user_session.destroy
        flash[:notice] = "Vous êtes maintenant déconnecté"
        redirect_to root_url
      end

    end
    {% endhighlight %}

Puis nous créons la vue correspondant au formulaire de connexion :

    # app/views/user_sessions/new.html.erb

    {% highlight erb %}
    <h1>Connexion</h1>

    <% form_for @user_session, :url => user_session_path do |f| -%>
      <%= f.error_messages %>
      <div>
        <%= f.label 'Email' %>
        <%= f.text_field :email %>
      </div>
      <div>
        <%= f.label 'Mot de passe' %>
        <%= f.password_field :password %>
      </div>
      <div>
        <%= f.check_box :remember_me %>
        <%= f.label "Se souvenir de moi" %>
      </div>
      <%= f.submit "Connexion" %>
    <% end -%>
    {% endhighlight %}

Nous pouvons maintenant nous rendre sur `http://localhost:3000`, nous y voyons "Bienvenue" ainsi que les liens de connexion et d'inscription. Une fois connecté, nous voyons apparaître l'email de l'utilisateur en cours ainsi que le lien de déconnexion.

[authlogic]: http://github.com/binarylogic/authlogic
[authlogic-exemple]: http://github.com/binarylogic/authlogic_example
[doc-authlogic]: http://rdoc.info/projects/binarylogic/authlogic