# Transit Dashboard

A transit dashboard that uses Shopify's [Dashing](http://shopify.github.com/dashing) to create a fancy display of DC area transit options.

Check out http://shopify.github.com/dashing for more information about Dashing.

[Here is a working example of a dashboard.](http://dashboard.derricklbryant.com/transitworktv)

## Requirements

- Ruby Gems
- Bundler gem
- [WMATA API key](https://developer.wmata.com/)
- [Car2Go API key](https://code.google.com/p/car2go/wiki/index_v2_1)
- [Uber API Key](https://developer.uber.com/)

## Getting Starting

From within the project root:

- Create the files [car2go-config.yaml](https://github.com/dbryant4/dashing-dashboard/blob/master/car2go-config.yaml.dist), [uber-config.yaml](https://github.com/dbryant4/dashing-dashboard/blob/master/uber-config.yaml.dist), [wmata-config.yaml](https://github.com/dbryant4/dashing-dashboard/blob/master/wmata-config.yaml.dist) in the root of the project. These are currently required and should be modeled after the corresponding ".dist" file.
- Install the bundler gem: `gem install bundler`
- Then start dashing: `dashing start`
- You can now visit [127.0.0.1:8080](127.0.0.1:8080) can see a sample dashboard.