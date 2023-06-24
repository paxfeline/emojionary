// Action Cable provides the framework to deal with WebSockets in Rails.
// You can generate new channels where WebSocket features live using the `bin/rails generate channel` command.

import { createConsumer } from "@rails/actioncable"

window.App = window.App || {}
App.cableConsumer = createConsumer();

// check for callback
if (App.cableConsumerCallback)
    App.cableConsumerCallback();

export default createConsumer()
