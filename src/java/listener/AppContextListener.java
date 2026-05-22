package listener;

import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.annotation.WebListener;

@WebListener
public class AppContextListener implements ServletContextListener {

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        System.out.println("=== IHVS Application Starting ===");
        // ReminderScheduler is now started automatically by its own @WebListener
        System.out.println("=== ReminderScheduler will start automatically ===");
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        System.out.println("=== IHVS Application Shutting Down ===");
    }
}