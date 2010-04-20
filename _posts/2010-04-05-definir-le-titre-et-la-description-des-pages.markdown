---
layout: post
title: Définir le titre et la description des pages
category: interaction
auteur: Matthieu Sadouni
chapo: Le titre et la description de chaque page d'un site sont très importants pour obtenir un bon référencement naturel. Voyons comment définir de manière très simple le titre et la description de nos pages.
description: |
  Comment définir le titre et la description des pages pour optimiser le référencement.
---

## Paramétrage du layout

Dans le layout principal `app/views/application.html.erb`, nous trouvons une ligne un peu particulière :

    {% highlight erb %}
    <html>
    <head>
      <title>Le titre</title>
      <meta name="description" content="La description" />
    <body>
      <div id="content">
        <%= yield %>
      </div>
    </body>
    </html>
    {% endhighlight %}

Ce `yield` définit un emplacement où sera inséré le contenu de la vue actuellement affichée. C'est en fait un raccourci pour `yield :content`, le contenu de la vue étant présent dans le symbole `:content`. Nous pouvons utiliser la même technique pour insérer le titre et la description de la page en ajoutant deux symboles `:title` et `:description` :

    {% highlight erb %}
    <html>
    <head>
      <title><%= yield(:title) ||= "Le titre par défaut" %></title>
      <meta name="description" content="<%= yield(:description) ||= "La description par défaut" %>" />
    <body>
      <div id="content">
        <%= yield %>
      </div>
    </body>
    </html>
    {% endhighlight %}

L'opérateur `||=` permet de n'affecter une valeur que si la valeur à gauche est `nil`. Nous pouvons ainsi omettre de définir le titre ou la description sans rencontrer d'erreur, la valeur par défaut donnée dans le layout étant alors prise en compte à la place.

Il ne nous reste plus qu'à renseigner `:title` et `:description` dans les vues.

## Définition depuis chaque page

Nous utilisons la méthode [`content_for`][content_for] qui sert à insérer du contenu dans un symbole. Le contenu de ce symbole est ensuite inséré dans le layout à l'appel du `yield` correspondant. Voyons ce que cela donne dans une vue :

    {% highlight erb %}
    <% content_for :title do %>
      Le titre de la page
    <% end %>
    <% content_for :description do %>
      La description de la page
    <% end %>
    <p>Le contenu.</p>
    {% endhighlight %}

Si nous reprenons le layout vu précédemment, le code HTML suivant est généré :

    {% highlight html %}
    <html>
    <head>
      <title>Le titre de la page</title>
      <meta name="description" content="La description de la page" %>" />
    <body>
      <div id="content">
        <p>Le contenu.</p>
      </div>
    </body>
    </html>
    {% endhighlight %}

Le seul petit souci est que nous devons ajouter 6 lignes de code à chaque vue. Nous remédions à cela en créant une méthode de helper pour simplifier nos vues :

    # app/helpers/application_helper.rb
    {% highlight ruby %}
    module ApplicationHelper

      def title(title)
        content_for(:title) { title }
      end

      def description(:description)
        content_for(:description) { description }
      end
    end
    {% endhighlight %}

Nous vérifions que le helper est inclus dans notre `ApplicationController` :

    # app/controllers/application_controller.rb
    {% highlight ruby %}
    helper :all
    {% endhighlight %}

Puis nous modifions notre vue en conséquence :

    {% highlight erb %}
    <% title "Le titre de la page" %>
    <% description "La description de la page" %>
    <p>Le contenu.</p>
    {% endhighlight %}

Nous pouvons maintenant définir facilement le titre et la description de chaque page. Cette combinaison de `yield` et `content_for` est très pratique pour modifier certains endroits du layout en fonction de la vue, comme par exemple une zone de navigation, une inclusion de javascript, etc.

[content_for]:http://api.rubyonrails.org/classes/ActionView/Helpers/CaptureHelper.html#M001763