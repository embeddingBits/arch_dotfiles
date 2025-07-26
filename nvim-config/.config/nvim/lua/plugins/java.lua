return {
  {
    "mfussenegger/nvim-jdtls",
    ft = { "java" },
    config = function()
      local jdtls = require("jdtls")
      local home = vim.env.HOME
      local mason_path = home .. "/.local/share/nvim/mason/packages/jdtls"
      local workspace_dir = home .. "/.local/share/java-workspaces/" .. vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")

      local config = {
        cmd = {
          "java",
          "-Declipse.application=org.eclipse.jdt.ls.core.id1",
          "-Dosgi.bundles.defaultStartLevel=4",
          "-Declipse.product=org.eclipse.jdt.ls.core.product",
          "-Dlog.protocol=true",
          "-Dlog.level=ALL",
          "-Xms1g",
          "--add-modules=ALL-SYSTEM",
          "--add-opens", "java.base/java.util=ALL-UNNAMED",
          "--add-opens", "java.base/java.lang=ALL-UNNAMED",
          "-jar", vim.fn.glob(mason_path .. "/plugins/org.eclipse.equinox.launcher_*.jar"),
          "-configuration", mason_path .. "/config_linux",
          "-data", workspace_dir,
        },
        root_dir = require("jdtls.setup").find_root({ ".git", "mvnw", "gradlew", "pom.xml" }),
        capabilities = require("cmp_nvim_lsp").default_capabilities(),
        settings = {
          java = {},
        },
        init_options = {
          bundles = {},
        },
      }

      jdtls.start_or_attach(config)
    end,
  }
}

