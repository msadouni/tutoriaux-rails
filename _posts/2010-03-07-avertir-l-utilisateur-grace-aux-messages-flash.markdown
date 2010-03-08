---
layout: post
title: Avertir l'utilisateur grâce aux messages flash
category: interaction
auteur: Matthieu Sadouni
chapo: Nous avons très souvent besoin dans une application de tenir l'utilisateur informé sur le résultat de ses actions. Cela peut être pour l'informer que son compte a bien été créé, qu'il y a une erreur de saisie dans un formulaire, etc. Il faut pouvoir créer ces messages dans les contrôleurs, puis les afficher sur la page suivante dans une boîte de couleur correspondant au type de message.
description: |
  Comment avertir l'utilisateur du résultat de ses actions grâce à des messages d'information.
---

Nous allons définir deux types de messages : succès (vert) et avertissement (orange).

### Création des messages

La création de messages est très simple, il suffit dans une action de contrôleur de stocker dans `flash` le contenu et le type de notre message :

    {% highlight ruby %}
    flash[:succes] = "L'article a bien été créé"
    {% endhighlight %}

De même pour créer un message d'avertissement :

    {% highlight ruby %}
    flash[:avertissement] = "Tous les champs obligatoires ne sont pas remplis"
    {% endhighlight %}

Nous aurons accès à `flash[:succes]` dans la vue lors de la requête suivante.

### Affichage des messages

Nous ajoutons à notre gabarit un bloc affichant les messages présents dans `flash` :

    # app/views/layouts/application.html.erb

    {% highlight erb %}
    <% flash.each do |key, msg| %>
      <%= content_tag(:div, content_tag(:p, msg), :class => "message #{key}") %>
    <% end %>
    {% endhighlight %}

Ce bloc va générer pour notre précédent message de succès le code HTML suivant :

    {% highlight html %}
    <div class="message">
      <div class="succes">
        <p>L'article a bien été créé</p>
      </div>
    </div>
    {% endhighlight %}

Et pour le message d'avertissement :

    {% highlight html %}
    <div class="message">
      <div class="avertissement">
        <p>L'article a bien été créé</p>
      </div>
    </div>
    {% endhighlight %}

Il ne nous reste plus qu'à styler ce bloc pour différencier les types de messages :

    # public/stylesheets/<fichier css>

    {% highlight css %}
    .message {
      margin-bottom: 10px;
    }
    .message div {
      padding: 10px 10px 15px 50px;
    }
    .message .succes {
      border: 1px solid #2b8a0d;
      background: url(/images/succes.gif) 10px 5px no-repeat;
      color: #2b8a0d;
    }
    .message .avertissement {
      border: 1px solid #dd4f00;
      background: url(/images/avertissement.gif) 10px 5px no-repeat;
      color: #dd4f00;
    }
    .message p {
      font-weight: bold;
    }
    {% endhighlight %}

### Résultat

Messages :

![Message de succès](http://img.skitch.com/20091029-86ber765rjpm53d3nwgyym7c7g.jpg)
![Message d'avertissement](http://img.skitch.com/20091029-b4r1x7iepyhuw5kwc4h1jiys68.jpg)

Icônes :

![Icône succès](http://img.skitch.com/20091029-gkbn8pwa8367fn8rjrhbbfqjr1.jpg)
![Icône avertissement](http://img.skitch.com/20091029-pun2heucqdj8duu7i4yxxkek49.jpg)

[famfamfam]: http://www.famfamfam.com/lab/icons/silk/