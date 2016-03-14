(require 'url)
(require 'json)

(defvar mm-token nil)
(defvar api-url-format "http://path.to.mattermost/api/%s")

(defun mm-request (token path)
  (let* ((url-http-end-of-headers nil)
         (bearer (format "Bearer %s" token))
         (url-request-extra-headers `(("Authorization" . ,bearer)))
         (resp-buffer ))
        (with-current-buffer (url-retrieve-synchronously (format api-url-format path))
          (goto-char url-http-end-of-headers)
          (buffer-string)
          (json-read))))

(defun mm-post (token path body)
  (let* ((url-request-method "POST")
         (url-request-data body)
         (url-http-end-of-headers nil)
         (bearer (format "Bearer %s" token))
         (url-request-extra-headers `(("Authorization" . ,bearer)))
         (resp-buffer ))
        (with-current-buffer (url-retrieve-synchronously (format api-url-format path))
          (goto-char url-http-end-of-headers)
          (buffer-string)
          (json-read))))


(defun mm-get-channels (token)
  (mm-request token "v1/channels/"))

(defun mm-get-channel (token chan-id)
  (mm-request token (format "v1/channels/%s/" chan-id)))

(defun mm-create-post (token chan-id message)
  (mm-post token (format "v1/channels/%s/create" chan-id)
           (json-encode `(:message ,message :channel_id ,chan-id))))

(defun mm-get-buffer-create (name)
  (get-buffer-create name))

(defvar-local mm-input-mark nil)
(defun reset-markers ()
  (setq mm-input-mark (make-marker))
  (set-marker mm-input-mark (point)))

(defun mm-mark-input-start ()
  (set-marker mm-input-mark (point) (current-buffer)))

(defvar matter-mode-map nil)
(if matter-mode-map
  nil
  (setq matter-mode-map (make-keymap))
  (define-key matter-mode-map (kbd "RET") 'mm-send))

(defun matter-mode ()
  (interactive)
  (kill-all-local-variables)
  (setq major-mode 'matter-mode)
  (setq mode-name "Mattermost")
  (use-local-map matter-mode-map))

(defun mm-send ()
  (interactive)
  (mm-create-post mm-token "iag3k7ic1prc9gpw86uijpqmqw" (buffer-substring mm-input-mark (point-max))))

(defun mm-open ()
  (let ((buffer (mm-get-buffer-create "Chat")))
    (set-buffer buffer)
    (matter-mode)
    (reset-markers)

    (goto-char (point-max))
    (forward-line 0)
    (insert "MM-> ")
    (mm-mark-input-start)

    (switch-to-buffer buffer)))

(mm-open)

(mm-get-channels mm-token)

(with-output-to-temp-buffer "asdf"
  (dolist (chan (mapcar (lambda (c) c) (cdr (assoc 'channels (mm-get-channels mm-token)))))
          (princ chan)
          (princ "\n"))
  (switch-to-buffer "asdf"))

(with-output-to-temp-buffer "asdf"
  (print (mm-get-channel mm-token "iag3k7ic1prc9gpw86uijpqmqw"))
  t)
