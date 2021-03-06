expose(Banana, as: 'application/banana+json') {

  writables :name, :number
  readables :curvature

  single(:first)  {
    via_get {
      allow do |*args|
        true
      end
    }
  }

  association(:apple)  {
    via_get {
      allow do |*args|
        true
      end
    }
  }

  collection(:query) {
    via_get {
      allow do |*args|
        true
      end
      handler do |uri_params|
        Banana.where(["number > ?", :uri_params[:gt]])
      end
    }
  }

  collection(:all) {
    via_get {
      allow do |*args|
        true
      end
    }
  }

  collection(:less_than_hundred) {
    via_get {
      allow do |*args|
        true
      end
    }
  }
}
