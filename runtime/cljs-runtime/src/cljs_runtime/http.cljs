(ns cljs-runtime.http)

(defonce http (js/require "http"))

(defn post [options callback]
  (.post http (clj->js options)
         (fn [response]
           (let [body-ref (atom "")]
             (.on response "data"
                  #(swap! body-ref str %))
             (.on response "end"
                  #(callback @body-ref))))))
