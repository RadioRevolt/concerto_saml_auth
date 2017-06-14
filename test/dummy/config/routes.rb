Rails.application.routes.draw do

  mount ConcertoSamlAuth::Engine => "/concerto_cas_auth"
end
