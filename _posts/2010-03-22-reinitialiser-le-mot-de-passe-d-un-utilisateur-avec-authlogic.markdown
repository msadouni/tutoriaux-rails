---
layout: post
title: Réinitialiser le mot de passe d'un utilisateur avec Authlogic
category: authentification
auteur: Matthieu Sadouni
chapo: Il arrive fréquemment qu'un utilisateur oublie son mot de passe. Nous allons lui permettre de le réinitialiser de manière simple et sûre grâce à Authlogic.
description: |
  Comment permettre à un utilisateur ayant perdu son mot de passe de le réinitialiser de manière simple et sûre.
---

Cet article s'appuie sur le [tutorial de Ben Johnson][tutorial-ben-johnson] et fait suite aux précédents articles sur [l'inscription][article-inscription] et sur [l'activation][article-activation] d'un compte utilisateur.

Le processus de réinitialisation d'un mot de passe suit les étapes suivantes :

1. l'utilisateur demande la réinitialisation de son mot de passe
2. un email contenant un lien de réinitialisation lui est envoyé
3. l'utilisateur clique sur le lien et arrive sur un formulaire où saisir son nouveau mot de passe
4. une fois le mot de passe modifié l'utilisateur est automatiquement connecté et le lien ayant servi à la réinitialisation est expiré

### Vérification de la présence des champs nécessaires

Nous allons avoir besoin de deux champs `email` et `perishable_token` sur le modèle `User`. Si vous avez suivi [le tutorial sur l'inscription d'un utilisateur][article-inscription] ces champs sont déjà présents et vous pouvez passer à l'étape suivante. Sinon, ajoutons-les à l'aide d'une migration.

Commençons par générer le fichier de migration :

    {% highlight bash %}
    script/generate migration add_users_passwords_reset_fields
    {% endhighlight %}

Nous ajoutons ensuite au fichier les champs nécessaires :

    # db/migrate/xxx_add_users_passwords_reset_fields.rb

    {% highlight ruby %}
    class AddUsersPasswordResetFields < ActiveRecord::Migration
      def self.up
        add_column :users, :perishable_token, :string, :default => '', :null => false
        add_column :users, :email, :string, :default => '', :null => false
        add_index :users, :perishable_token
        add_index :users, :email
      end

      def self.down
        remove_column :users, :perishable_token
        remove_column :users, :email
      end
    end
    {% endhighlight %}

Appliquons enfin la migration :

    {% highlight bash %}
    rake db:migrate
    {% endhighlight %}

Le modèle User est maintenant prêt, nous pouvons passer à l'étape suivante.

### Demande de réinitialisation du mot de passe

Nous allons avoir besoin d'un formulaire permettant à un utilisateur de saisir son email pour recevoir le lien de réinitialisation. Pour nous conformer à la méthode REST, nous allons créer une resource `PasswordReset`. Une demande de réinitialisation correspond alors à la création d'une `PasswordReset` (action `create` du contrôleur `PasswordResetsController`). Nous créons ce contrôleur :

    {% highlight bash %}
    script/generate controller password_resets
    {% endhighlight %}

Nous y ajoutons deux actions `new` et `create` correspondant respectivement à l'affichage du formulaire et à son traitement :

    # app/controllers/password_resets_controller.rb

    {% highlight ruby %}
    class PasswordResetsController < ApplicationController
      def new
      end

      def create
        @user = User.find_by_email(params[:email])
        if @user
          @user.deliver_password_reset_instructions!
          flash[:succes] = "Les instructions vous permettant de réinitialiser votre mot de passe vous ont été envoyées par email."
          redirect_to root_url
        else
          flash[:avertissement] = "Aucun utilisateur n'a été trouvé avec cette adresse email."
          render :action => :new
        end
      end
    end
    {% endhighlight %}

La méthode `deliver_password_reset_instructions!` initialise le champ `perishable_token` et envoie un email contenant le lien de réinitialisation. Voyons le code de cette méthode dans le modèle `User` :

    # app/models/user.rb

    {% highlight ruby %}
    class User < ActiveRecord::Base
      def deliver_password_reset_instructions!
        reset_perishable_token!
        UserMailer.deliver_password_reset_instructions(self)
      end
    end
    {% endhighlight %}

La méthode `reset_perishable_token!` est fournie par Authlogic, elle génère un nouveau `perishable_token` et sauvegarde l'enregistrement.

Nous ajoutons au `UserMailer` créé dans [le précédent article sur l'inscription d'un utilisateur][article-inscription] le code suivant :

    # app/models/user_mailer.rb

    {% highlight ruby %}
    class UserMailer < ActionMailer::Base
      def password_reset_instructions(user)
        subject "Instructions pour la réinitialisation de votre mot de passe"
        from "no-reply@example.com"
        recipients user.email
        sent_on Time.now
        body :edit_password_reset_url => edit_password_reset_url(user.perishable_token)
      end
    end
    {% endhighlight %}

L'adresse `edit_password_reset_url` correspond au formulaire de saisie de nouveau mot de passe que nous allons créer dans un instant. Il ne nous manque plus pour cette étape que le contenu de l'email, du formulaire et la route permettant d'accéder au différentes actions. Commençons par l'email :

    # app/views/user_mailer/password_reset_instructions.erb

    {% highlight erb %}
    Une demande de réinitialisation de mot de passe a été faite pour votre compte sur le site example.com.

    Si vous n'avez pas effectué cette demande, vous pouvez ignorer cet email

    Si vous avez effectué cette demande, il vous suffit de cliquer sur le lien ci-dessous pour indiquer votre nouveau mot de passe.

    <%= @edit_password_reset_url %>

    Si l'adresse ci-dessus ne fonctionne pas, tentez de la copier / coller directement dans votre navigateur.

    Si vous rencontrez un problème, n'hésitez pas à nous contacter.
    {% endhighlight %}

Puis le formulaire :

    # app/views/password_resets/new.erb

    {% highlight erb %}
    <h1>Mot de passe oublié ?</h1>

    <p>Indiquez votre email ci-dessous et les instructions vous permettant de réinitialiser votre mot de passe vous seront envoyées.</p>

    <% form_tag password_resets_path do %>
      <div>
        <label>Email</label>
        <%= text_field_tag "email" %>
      </div>
      <div>
        <%= submit_tag "Réinitialiser mon mot de passe" %>
      </div>
    <% end %>
    {% endhighlight %}

Et enfin les routes :

    # config/routes.rb

    {% highlight ruby %}
    map.resources :password_resets
    {% endhighlight %}

Un utilisateur peut maintenant demander la réinitialisation de son mot de passe vers laquelle nous pouvons créer un lien avec la méthode `new_password_reset_url`. Voyons maintenant ce qu'il se passe une fois l'email reçu.

### Réinitialisation du mot de passe

Lorsque l'utilisateur clique sur le lien contenu dans l'email, il est envoyé sur l'action `edit` du contrôleur `PasswordResets` pour modifier son mot de passe. Nous lui ajoutons le code nécessaire :

    # app/controllers/password_resets_controller.rb

    {% highlight ruby %}
    before_filter :load_user_using_perishable_token, :only => [:edit, :update]

    def edit
    end

    def update
      @user.password = params[:user][:password]
      @user.password_confirmation = params[:user][: password_confirmation]
      if @user.save
        flash[:notice] = "Le mot de passe a bien été modifié"
        redirect_to account_url
      else
        flash[:avertissement] = "Le mot de passe n'a pas pu être modifié"
        render :action => :edit
      end
    end

    private

    def load_user_using_perishable_token
      @user = User.find_using_perishable_token(params[:id])
      unless @user
        flash[:notice] = "Nous sommes désolés, nous n'avons pas pu retrouver votre compte. " +
        "Si vous rencontrez un problème, tentez de copier / coller l'adresse " +
        "depuis l'email dans votre navigateur, ou recommencez " +
        "le processus de réinitialisation du mot de passe"
        redirect_to root_url
      end
    end
    {% endhighlight %}

La méthode `load_user_using_perishable_token` permet de retrouver l'utilisateur à partir du `perishable_token` contenu dans le lien. Elle utilise la méthode `find_using_perishable_token` fournie par Authlogic ; cette méthode s'assure que le token utilisé n'est pas vide et est toujours valide, Authlogic expirant automatiquement les tokens au bout de 10 minutes.

L'utilisateur est retrouvé avant l'appel aux deux actions `edit` et `update` grâce au `before_filter`. Si la modification du mot de passe réussit, l'utilisateur est automatiquement connecté grâce à Authlogic.

Nous créons le formulaire de réinitialisation du mot de passe :

    # app/views/password_resets/edit.erb

    {% highlight erb %}
    <h1>Modifier mon mot de passe</h1>

    <% form_for @user, :url => password_reset_path, :method => :put do |f| %>
      <%= f.error_messages %>
      <div>
        <%= f.label :password, "Mot de passe" %>
        <%= f.password_field :password %>
      </div>
      <div>
        <%= f.label :password_confirmation, "Saisissez à nouveau votre mot de passe" %>
        <%= f.password_field :password_confirmation %>
      </div>
      <div>
        <%= f.submit "Modifier mon mot de passe et me connecter" %>
      </div>
    <% end %>
    {% endhighlight %}

Il ne nous reste plus qu'à restreindre l'accẻs en s'assurant que seul un utilisateur non connecté peut réinitialiser son mot de passe. Nous allons pour cela ajouter un autre `before_filter` appelant une méthode `require_no_user` présente dans `ApplicationController` :

    # app/controllers/application_controller.rb

    {% highlight ruby %}
    def require_no_user
      if current_user
        store_location
        flash[:avertissement] = "Vous devez être déconnecté pour accéder à cette page"
        redirect_to root_url
        return false
      end
    end

    def store_location
      session[:return_to] = request.request_uri
    end
    {% endhighlight %}

    # app/controllers/password_resets_controller

    {% highlight ruby %}
    before_filter :require_no_user
    {% endhighlight %}

Nos utilisateurs ont maintenant la possibilité de réinitialiser leur mot de passe de manière simple, sûre et conforme à la méthode REST.

[tutorial-ben-johnson]: http://www.binarylogic.com/2008/11/16/tutorial-reset-passwords-with-authlogic/
[article-activation]: /articles/activation-d-un-compte-utilisateur-avec-authlogic/
[article-inscription]: /articles/inscription-et-connexion-d-un-utilisateur-avec-authlogic/
