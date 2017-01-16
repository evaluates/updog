module Api
    class DropboxController < ApplicationController
      def files
        render json: dropbox_files
      end
      def folders
        render json: dropbox_folders
      end
    end
end
