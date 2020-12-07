1. Invite bot to your discord
2. Check source channel id (last number from URL)
3. Check target channel id (last number from URL)
4. Ensure bot have access to write to target channel
5. Fetch your user's cookie and auth token from devtools (headers for any api request)
6. You can setup many channels as array
7. Copy `config.example.yml` to `config.example`
8. `bundle install`
9. `bundle exec ruby main.rb`
10. Use any supervisor (docker, systemd) to monitor app
