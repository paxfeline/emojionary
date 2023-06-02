import consumer from "channels/consumer"

consumer.subscriptions.create(
  {
    channel: "GamesChannel",
    game_id: new URLSearchParams(document.location.search).get("game_id")
  },
  {
    connected() {
      // Called when the subscription is ready for use on the server
    },

    disconnected() {
      // Called when the subscription has been terminated by the server
    },

    received(data) {
      // Called when there's incoming data on the websocket for this channel
    }
  }
);
