(ns runtime.handler
  (:require [cljs.js :refer [eval-str]]
            [clojure.string :as string]
            [goog.object :as gobj]))

;; Node.js Interop

(defonce child-process
  (js/require "child_process"))

(defonce exec-sync
  (gobj/get child-process "execSync"))

(defn env [key]
  (gobj/getValueByKeys js/process "env" key))

;; Variables

(defonce base-path
  (str "http://" (env "AWS_LAMBDA_RUNTIME_API")
       "/2018-06-01/runtime/invocation/"))

(defonce handler (env "_HANDLER"))

;; Lambda lifecycle methods

(defn curl-request [headers]
  (exec-sync (str "curl -sS -LD \"" headers "\" "
                  "-X GET \"" base-path "next\"")))

(defn request-id [headers]
  (-> (str "grep -Fi Lambda-Runtime-Aws-Request-Id "
           "\"" headers "\" | tr -d '[:space:]'")
      exec-sync
      (string/split #":")
      last))

(defn curl-response [headers response]
  (exec-sync (str "curl -X POST \""
                  base-path
                  (request-id headers) "/response\" -d \"" response "\"")))

;; Handler

(while true
  (let [headers (exec-sync "mktemp")
        event (curl-request headers)]

    (prn handler)

    (try
      (eval-str (atom nil)
                (str "(" handler ")")
                (fn [{:keys [value]}]
                  (curl-response headers value)))

      (catch :exception e
        (prn e)
        (curl-response headers "ERROR")))))
