//
//  PrivacyPolicyView.swift
//  Zap
//
//  Created by Zigao Wang on 9/28/24.
//

import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            Text(privacyPolicy)
                .padding()
        }
        .navigationTitle("Privacy Policy")
    }
    
    private var privacyPolicy: String {
        let preferredLanguages = Bundle.main.preferredLocalizations
        let isChineseLanguage = preferredLanguages.first?.hasPrefix("zh") ?? false
        
        if isChineseLanguage {
            return """
            Zap 笔记隐私政策

            1. 信息收集
            目前，Zap 不会收集用户的任何个人信息。我们致力于保护您的隐私并确保安全的用户体验。

            2. 第三方服务
            我们使用 https://uniapi.ai/ 作为 OpenAI 服务的代理。请参阅 UniAPI 的隐私政策（https://api.uniapi.ai/privacy）以了解他们如何处理数据。

            3. 开源
            Zap 是一个开源项目。我们所有的代码都在 GNU 通用公共许可证 v3.0 (GPL-3.0) 下提供，可以在 GitHub 上找到：
            - 应用：https://github.com/ZigaoWang/Zap
            - 后端：https://github.com/ZigaoWang/Zap-backend

            4. 未来更新
            本隐私政策仍在完善中。随着应用的进一步开发，我们可能会更新本政策以反映数据处理方面的任何变化。我们会通知用户任何重大变更。

            5. 联系我们
            如果您对本隐私政策有任何疑问，请通过 a@zigao.wang 与我们联系。

            最后更新：2024年10月17日
            """
        } else {
            return """
            Privacy Policy for Zap Notes

            1. Information Collection
            At present, Zap does not collect any personal information from its users. We are committed to protecting your privacy and ensuring a secure user experience.

            2. Third-Party Services
            We use https://uniapi.ai/ as a proxy for OpenAI services. Please refer to UniAPI's privacy policy (https://api.uniapi.ai/privacy) for information on how they handle data.

            3. Open Source
            Zap is an open-source project. All of our code is available under the GNU General Public License v3.0 (GPL-3.0) and can be found on GitHub:
            - App: https://github.com/ZigaoWang/Zap
            - Backend: https://github.com/ZigaoWang/Zap-backend

            4. Future Updates
            This privacy policy is a work in progress. As we develop our app further, we may update this policy to reflect any changes in data handling. We will notify users of any significant changes.

            5. Contact Us
            If you have any questions about this Privacy Policy, please contact us at a@zigao.wang.

            Last updated: October 17, 2024
            """
        }
    }
}
