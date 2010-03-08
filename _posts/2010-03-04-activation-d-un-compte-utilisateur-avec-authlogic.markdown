---
layout: post
title: Activation d'un compte utilisateur avec Authlogic
category: authentification
chapo: Lors de l'inscription d'un utilisateur, nous souhaitons vérifier que l'email donné est valide avant d'activer son compte. Voyons comment réaliser cela de manière élégante avec Authlogic.
description: |
  Comment vérifier avec Authlogic l'email d'un utilisateur souhaitant s'inscrire.
---

Cet article est une traduction adaptée du [tutorial de Matt Hooks][tutorial-matt-hooks] et fait suite au [précédent article][article-authlogic] sur l'inscription et la connexion d'utilisateurs.

## Préparation du modèle User

Nous allons ajouter au modèle User une colonne `actif` qui indiquera si l'utilisateur a vérifié son adresse email. Nous commençons par créer une migration :

    {% highlight bash %}
    script/generate migration add_actif_to_user actif:boolean
    {% endhighlight %}

Rails reconnaît dans cette commande que nous souhaitons ajouter à la table `users` une colonne `actif` stockant un booléen. Il génère le fichier suivant :

    # db/migrate/xxxx_add_actif_to_users.rb

    {% highlight ruby %}
    class AddActifToUsers < ActiveRecord::Migration
      def self.up
        add_column :users, :actif, :boolean
      end

      def self.down
        remove_column :users, :actif
      end
    end
    {% endhighlight %}

Nous modifions la ligne `add_column` pour spécifier que la colonne est à `false` par défaut, et ne peut être nulle :

    {% highlight ruby %}
    add_column :users, :active, :boolean, :default => false, :null => false
    {% endhighlight %}

Nous appliquons la migration sur la base de données :

    {% highlight bash %}
    rake db:migrate
    {% endhighlight %}

Authlogic exécute automatiquement la méthode `active?` si elle est présente sur le modèle. Nous modifions le modèle User pour ajouter cette méthode, et nous en profitons pour empêcher l'assignation en masse des attributs sensibles. Cela évitera qu'un utilisateur puisse activer son compte en envoyant un formulaire créé de toute pièce ([en savoir plus sur `attr_accessible`][attr_accessible]).

    # app/models/user.rb

    {% highlight ruby %}
    class User < ActiveRecord::Base

      attr_accessible :email, :password, :password_confirmation

      def active?
        actif
      end
    end
    {% endhighlight %}

Si nous essayons de nous connecter après nous être inscrit, nous recevons comme prévu un message nous indiquant que notre compte n'est pas actif.

## Activation d'un compte utilisateur

Nous allons utiliser le `perishable_token` fourni par Authlogic pour le processus d'activation. Lorsqu'un utilisateur s'inscrit, il reçoit un email contenant un lien unique d'activation valable pendant un certain temps (ici une semaine). Ce lien contient le `perishable_token` de l'utilisateur et nous permet de le retrouver. Il n'a plus qu'à cliquer sur "Activer mon compte" pour pouvoir se connecter.

Nous commençons par modifier l'action `create` du contrôleur `UsersController` :

    # app/controllers/users_controller.rb

    {% highlight ruby %}
    def create
      @user = User.new(params[:user])

      # le user n'est pas encore activé, on désactive le login automatique
      if @user.save_without_session_maintenance
       @user.deliver_activation_instructions!
       flash[:notice] = "Votre compte a bien été créé." +
         "Vous allez recevoir un email contenant les instructions pour l'activer."
       redirect_to root_url
      else
       render :action => :new
      end
    end
    {% endhighlight %}

Puis nous créons un contrôleur `ActivationsController` chargé de gérer le processus d'activation. Il contient deux actions :

- `new` retrouve l'utilisateur à partir du `perishable_token` et lui présente le formulaire "Activer mon compte"
- `create` active l'utilisateur et lui envoie l'email de confirmation

Nous créons ce contrôleur :

    {% highlight bash %}
    script/generate controller activations new create
    {% endhighlight %}

Puis nous y ajoutons le code des deux actions :

    # app/controllers/activations_controller.rb

    {% highlight ruby %}
    class ActivationsController < ApplicationController

      def new
        @user = User.find_using_perishable_token(params[:activation_code], 1.week) || (raise Exception)
        raise Exception if @user.active?
      end

      def create
        @user = User.find(params[:id])

        raise Exception if @user.active?

        if @user.activate!
          @user.deliver_activation_confirmation!
          redirect_to root_url
        else
          render :action => :new
        end
      end

    end
    {% endhighlight %}

Les exceptions servent à empêcher l'activation d'un utilisateur déjà activé ou au `perishable_token` expiré. Vous voudrez certainement remplacer cette gestion d'erreur par quelque chose de plus élaboré, comme la possibilité pour un utilisateur dont le `perishable_token` a expiré d'en demander un nouveau.

Nous créons la vue correspondant à l'activation :

    # app/views/activations/new.html.erb

    {% highlight erb %}
    <h1>Activez votre compte</h1>

    <% form_for @user, :url => activate_path(@user.id), :html => { :method => :post } do |f| %>
      <%= f.error_messages %>
      <%= f.submit "Activer mon compte" %>
    <% end %>
    {% endhighlight %}

Ces contrôleurs font appel à un certain nombre de méthodes du modèle User qui n'existent pas encore. Remédions à cela :

    # app/models/user.rb

    {% highlight ruby %}
    def activate!
      self.actif = true
      save
    end

    def deliver_activation_instructions!
      reset_perishable_token!
      UserMailer.deliver_activation_instructions(self)
    end

    def deliver_activation_confirmation!
      reset_perishable_token!
      UserMailer.deliver_activation_confirmation(self)
    end
    {% endhighlight %}

Il ne nous manque plus que les envois d'emails, nous générons pour cela `UserMailer` :

    {% highlight bash %}
    script/generate user_mailer activation_instructions activation_confirmation
    {% endhighlight %}

Puis nous ajoutons le code suivant au mailer :

    # app/models/user_mailer.rb

    {% highlight ruby %}
    class UserMailer < ActionMailer::Base

      def activation_instructions(user)
        subject       "Veuillez confirmer la création de votre compte"
        from          "Mon Appli <noreply@example.com>"
        recipients    user.email
        sent_on       Time.now
        body          :account_activation_url => register_url(user.perishable_token)
      end

      def activation_confirmation(user)
        subject       "Votre compte a bien été créé"
        from          "Mon Appli <noreply@example.com>"
        recipients    user.email
        sent_on       Time.now
        body          :root_url => root_url
      end

    end
    {% endhighlight %}

Nous ajoutons les routes utilisées dans le mailer :

    # config/routes.rb

    {% highlight ruby %}
    map.register '/register/:activation_code', :controller => 'activations', :action => 'new'
    map.activate '/activate/:id', :controller => 'activations', :action => 'create'
    {% endhighlight %}

Nous créons enfin les vues contenant les instructions d'activation :

    # app/views/user_mailer/activation_instructions.html.erb

    {% highlight erb %}
    Nous vous remercions d'avoir créé un compte. Veuillez cliquer sur le lien ci-dessous pour l'activer :

    <%= @account_activation_url %>
    {% endhighlight %}

et de confirmation de l'activation :

    # app/views/user_mailer/activation_confirmation.html.erb

    {% highlight erb %}
    Votre compte a bien été activé.

    <%= @root_url %>
    {% endhighlight %}

Dernière chose pour les emails, il faut indiquer à Rails quelle url de base utiliser pour la génération des liens :

    # config/environments/development.rb

    {% highlight ruby %}
    config.action_mailer.default_url_options = {
      :host => 'localhost:3000'
    }
    {% endhighlight %}

Vérifions maintenant que tout fonctionne. Nous nous rendons sur http://localhost:3000/users/new et créons un utilisateur. Nous voyons dans le log du serveur l'email envoyé avec le lien d'activation. Nous copions ce lien et nous rendons sur `http://localhost:3000/user_session/new` pour tenter de nous connecter. Nous obtenons bien un message d'erreur nous indiquant que le compte n'est pas actif.

Nous pouvons alors copier/coller dans notre navigateur l'adresse récupérée dans l'email (de la forme `http://localhost:3000/register/:perishable_token`). Nous voyons alors la page contenant le bouton "Activer mon compte" sur lequel nous cliquons. Nous voyons dans le log du serveur l'email de confirmation, il est maintenant possible de se connecter.

Tout cela est déjà bien pratique, mais ne serait-ce pas mieux si nous étions connecté dès l'activation du compte ? Voyons comment mettre en place ce processus.

## Connexion dès l'activation

Authlogic connecte automatiquement l'utilisateur lors de la modification du mot de passe, or ici le mot de passe n'a pas été modifié. Nous allons donc modifier le processus pour ne demander que l'email à l'inscription et demander le mot de passe lors de l'activation, connectant ainsi l'utilisateur en même temps.

Nous commençons par indiquer à Authlogic de ne vérifier la longueur du mot de passe que si celui-ci est vide lors d'un `update` :

    # app/models/user.rb

    {% highlight ruby %}
    acts_as_authentic do |c|
      c.validates_length_of_password_field_options = {
        :on => :update, :minimum => 4, :if => :has_no_credentials?
      }
      c.validates_length_of_password_confirmation_field_options = {
        :on => :update, :minimum => 4, :if => :has_no_credentials?
      }
    end

    def has_no_credentials?
      self.crypted_password.blank?
    end
    {% endhighlight %}

Nous séparons ensuite l'inscription d'un utilisateur en deux processus :

- `signup!` qui affecte l'email choisi et sauvegarde sans login automatique
- `activate!` qui affecte le mot de passe choisi et sauvegarde avec login automatique

Nous modifions de nouveau le modèle `User` :

    # app/models/user.rb

    {% highlight ruby %}
    def signup!(params)
      self.email = params[:user][:email]
      # Ces colonnes sont NOT NULL, on évite une erreur SQL
      self.crypted_password = ''
      self.password_salt = ''
      save_without_session_maintenance
    end

    def activate!(params)
      self.actif = true
      self.password = params[:user][:password]
      self.password_confirmation = params[:user][:password_confirmation]
      save
    end
    {% endhighlight %}

Nous modifions ensuite la méthode `create` des contrôleurs `ActivationsController` et `UsersController` pour utiliser nos nouvelles méthodes `signup!` et `activate!`.

Nous commençons par `UsersController` :

    # app/controllers/users_controller.rb

    {% highlight ruby %}
    def create
      @user = User.new

      if @user.signup!(params)
        @user.deliver_activation_instructions!
        flash[:notice] = "Votre compte a bien été créé." +
          "Vous allez recevoir un email contenant les instructions pour l'activer."
        redirect_to root_url
      else
        render :action => :new
      end
    end
    {% endhighlight %}

Puis `ActivationsController` :

    # app/controllers/activations_controller.rb

    {% highlight ruby %}
    def create
      @user = User.find(params[:id])

      raise Exception if @user.active?

      if @user.activate!(params)
        @user.deliver_activation_confirmation!
        flash[:notice] = "Votre compte a bien été activé."
        redirect_to root_url
      else
        render :action => :new
      end
    end
    {% endhighlight %}

Il ne nous reste plus qu'à modifier les formulaires. Nous commençons par supprimer le mot de passe lors de l'inscription :

    # app/views/users/new.html.erb

    {% highlight erb %}
    <h1>Créer un compte</h1>

    <% form_for @user do |f| %>
      <%= f.error_messages %>
      <div>
        <%= f.label 'Email' %>
        <%= f.text_field :email %>
      </div>
      <%= f.submit "Créer mon compte" %>
    <% end %>
    {% endhighlight %}

Puis nous l'ajoutons lors de l'activation :

    # app/views/activations/new.html.erb

    {% highlight erb %}
    <h1>Activez votre compte</h1>

    <% form_for @user, :url => activate_path(@user.id), :html => { :method => :post } do |f| %>
      <%= f.error_messages %>
      <div>
        <%= f.label :password, "Mot de passe" %>
        <%= f.password_field :password %>
      </div>
      <div>
        <%= f.label :password_confirmation, "Confirmer le mot de passe" %>
        <%= f.password_field :password_confirmation %>
      </div>
      <%= f.submit "Activer mon compte" %>
    <% end %>
    {% endhighlight %}

[article-authlogic]: /articles/inscription-et-connexion-d-un-utilisateur-avec-authlogic
[tutorial-matt-hooks]: http://github.com/matthooks/authlogic-activation-tutorial
[attr_accessible]: http://railspikes.com/2008/9/22/is-your-rails-application-safe-from-mass-assignment