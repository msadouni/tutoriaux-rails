---
layout: post
title: Annuler la suppression d'un enregistrement avec ActsAsArchive
category: interaction
auteur: Matthieu Sadouni
chapo: En général, dans une application, nous demandons confirmation à l'utilisateur avant de supprimer un enregistrement. Cependant il est facile de cliquer trop rapidement sur "Ok", et l'enregistrement est alors supprimé sans possibilité d'annulation. Voyons comment archiver un enregistrment au lieu de le supprimer complètement, et comment proposer l'annulation de la suppression.
description: |
  Comment archiver un enregistrement supprimé et proposer sa restauration avec ActsAsArchive.
---

## Raison et principe

[Cet excellent article du site A List Apart][alistapart] (en anglais) explique en détail pourquoi il est plus judicieux de proposer l'annulation d'une action plutôt que d'en demander confirmation. Pour résumer, à force d'habitude nous ne lisons plus les messages de confirmation et cliquons machinalement sur "Ok". Une solution est alors d'accepter directement l'action effectuée par l'utilisateur et de lui proposer la possibilité de l'annuler en cas d'erreur, comme lors de la suppression d'un email sur Gmail.

[ActsAsArchive][actsasarchive] permet de déplacer les enregistrements supprimés de la table d'origine dans une table à part. Si la structure de la table d'origine est modifiée dans une migration, celle de la table d'archivage l'est également. Il offre également la possibilité de restaurer un enregistrement.

## Installation

Nous ajoutons au fichier `config/environment.rb` la gem ActsAsArchive, dépaquetons le code et versionnons le tout :

    # config/environnement.rb
    {% highlight ruby %}
    config.gem 'acts_as_archive'
    {% endhighlight %}

    {% highlight bash %}
    $ sudo rake gems:install
    $ rake gems:unpack:dependencies
    $ git add .
    $ git commit -am "ActsAsArchive"
    {% endhighlight %}

## Archivage d'un enregistrement

Nous commençons par indiquer au modèle que les suppressions sont gérées par ActsAsArchive :

    # app/models/post.rb
    {% highlight ruby %}
    class Post < ActiveRecord::Base
      acts_as_archive
    end
    {% endhighlight %}

Puis nous générons un fichier de migration pour créer la table d'archivage :

    {% highlight bash %}
    script/generate migration add_acts_as_archive_to_posts
    {% endhighlight %}

    # db/migrate/xxxx_add_acts_as_archive_to_posts.rb
    {% highlight ruby %}
    class AddActsAsArchiveToPosts < ActiveRecord::Migration
      def self.up
        ActsAsArchive.update Post
      end

      def self.down
        drop_table :archived_posts
      end
    end
    {% endhighlight %}

    {% highlight bash %}
    rake db:migrate
    {% endhighlight %}

La table `archived_posts` est créée, elle possède la même structure que `posts` et sera mise à jour automatique si la structure de `posts` est modifiée dans une future migration.

À partir de maintenant, tout appel à `delete`, `destroy` ou `delete_all` sur une instance de `Post` déplace le(s) enregistrement(s) concerné(s) dans la table `archived_posts`.

## Annulation de la suppression

ActsAsArchive fournit une méthode `restore_all` permettant de restaurer des enregistrements supprimés. Un `id` peut lui être passé en paramètre pour spécifier un enregistrement particulier. Une première possibilité pour effectuer une annulation serait de créer une action `restore` sur le contrôler `PostsController`. Pour nous conformer à la méthode REST, nous allons plutôt considérer cette annulation comme la suppression d'un `ArchivedPost` (action `destroy` du contrôleur `ArchivedPostsController`. Nous générons ce contrôleur et y ajoutons le code nécessaire :

    {% highlight bash %}
    script/generate controller archived_posts
    {% endhighlight %}

    # app/controllers/archived_posts_controller.rb

    {% highlight ruby %}
    class ArchivedPostsController < ApplicationController
      def destroy
        Post.restore_all(['id = ?', params[:id]])
        flash[:success] = "Le post a bien été restauré."
        redirect_to posts_path and return
      end
    end
    {% endhighlight %}

Il ne nous reste plus qu'à afficher un lien vers l'action d'annulation dans le message flash de suppression d'un post :

    # app/controllers/posts_controller.rb

    {% highlight ruby %}
    def destroy
      @post = Post.find(params[:id])
      if @post.destroy
        flash[:success] = "Le post a bien été supprimé. " +
          @template.button_to("Annuler", {:controller => :archived_posts, :action => :destroy, :id => @post.id}, :method => :delete)
        redirect_to posts_path and return
      end
    end
    {% endhighlight %}

La variable `@template` permet d'accéder aux méthodes de helpers disponibles dans les vues pour générer le bouton de suppression. Dans la vue `index` du controller `PostsController`, nous pouvons alors remplacer le lien de suppression avec confirmation par un simple bouton :

    {% highlight erb %}
    <% @posts.each do |post| %>
      <%= post.title %>
      <%= button_to "Supprimer", {:action => :destroy, :id => post.id}, :method => :delete %>
    <% end %>
    {% endhighlight %}

[alistapart]: http://www.alistapart.com/articles/neveruseawarning/
[actsasarchive]: http://github.com/winton/acts_as_archive